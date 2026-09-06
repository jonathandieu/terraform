# ADR 0001 — Gateway API implementation: Envoy Gateway

- **Status:** Accepted
- **Date:** 2026-06-23
- **Deciders:** Jonathan Dieu
- **Applies to:** all clusters (`charts/infrastructure/envoy-gateway` in `dieubernetes`)

## Context

dieu.dev runs on managed Kubernetes across clouds — DOKS today, EKS planned — with
ArgoCD GitOps and a hard commitment to **Gateway API (`HTTPRoute`), not `Ingress`**.
The data-plane / routing layer must satisfy several constraints specific to this setup:

1. **Multi-cloud on managed control planes.** Clusters are managed (DOKS now, EKS
   later), so the cloud provider owns the CNI. The routing layer must be a portable
   workload that runs identically on every cloud, independent of who controls the CNI.
2. **Pre-provisioned L4 LB adoption.** Terraform pre-provisions the cloud load balancer
   and the gateway adopts it via a Service annotation (`do-loadbalancer-id` on DO, NLB
   annotations on AWS). The implementation must expose the gateway Service so these
   annotations can be set per-cloud.
3. **Gateway-API-native.** `HTTPRoute` is the routing primitive everywhere; the
   implementation should treat Gateway API as a first-class model, not a bolt-on.
4. **Progressive delivery roadmap.** Argo Rollouts canary via weighted `HTTPRoute`
   `backendRefs` is planned.
5. **Small clusters.** 1–3 nodes, `s-2vcpu-*`. Footprint matters.

## Decision

Use **Envoy Gateway** as the Gateway API implementation on every cluster.

The pre-provisioned cloud LB is adopted via `EnvoyProxy` → `provider.kubernetes.envoyService.annotations`,
set per-cluster in `dieubernetes/clusters/<name>/overrides/envoy-gateway.yaml`.

## Rationale / alternatives considered

The candidates are not apples-to-apples — that distinction drove the decision.

| Option | What it is | Verdict |
|---|---|---|
| **Envoy Gateway** | Gateway API impl on an Envoy data plane; purpose-built for Gateway API. | **Chosen.** Best fit for all five constraints. |
| **Traefik** | General ingress controller with its own `IngressRoute` CRDs *plus* Gateway API support. | Viable downgrade. Gateway API is its second-class path; choosing it means skipping the mature CRDs that are most of its appeal. |
| **ingress-nginx** | Ingress-only controller. | Eliminated — we've ruled out `Ingress`. |
| **NGINX Gateway Fabric** | The NGINX camp's real Gateway API impl. | Viable but less feature-rich than Envoy Gateway; no advantage for our needs. |
| **Cilium** | A CNI / eBPF networking layer that also implements Gateway API. | Eliminated for managed clusters — requires *owning* the Cilium install with L7/Gateway flags enabled, which managed control planes (DOKS/EKS) don't expose. Cuts against the portability goal. |

Why Envoy Gateway wins on the constraints that matter:

- **Portability (constraint 1):** a pure workload that runs identically on any managed
  cloud. Cilium Gateway API would require self-managed networking on every cloud.
- **LB adoption (constraint 2):** `EnvoyProxy` annotations give clean per-cloud control
  of the gateway Service; already wired in this repo.
- **Gateway-API-native (constraint 3):** no legacy `Ingress` model to work around.
- **Canary (constraint 4):** first-class target for the Argo Rollouts Gateway API plugin
  (weighted `backendRefs`).
- **Headroom:** Envoy's ecosystem (rate limiting, ext-authz, WASM, richer `*Policy` CRDs)
  is available if we grow into it.

The honest argument *against* Envoy Gateway is footprint/complexity on 1-node clusters
(constraint 5), where Traefik is lighter and simpler.

## Consequences

- All routing is `HTTPRoute`; no `Ingress` resources anywhere.
- Per-cluster LB adoption lives in the `envoy-gateway.yaml` override and is populated by
  `dieuctl cluster create` from the Terraform `lb_id` output.
- We carry Envoy's resource overhead on small clusters as an accepted cost.

## Revisit if

- **→ Traefik (Gateway API mode):** if Envoy's resource use / operational complexity
  proves annoying on small clusters and we never use Envoy's policy features. The
  cheapest pivot; still keeps `HTTPRoute`.
- **→ Cilium:** only if we move to **self-managed** Kubernetes (kubeadm/Talos) and want
  to consolidate CNI + LB IPAM + NetworkPolicy + Gateway + mesh into one stack. That is a
  networking-consolidation decision, not just an ingress choice, and is at odds with the
  current managed-cluster direction.
- **→ NGINX Gateway Fabric:** only if a hard requirement for the NGINX data plane appears.
