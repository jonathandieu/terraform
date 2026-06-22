# Infrastructure Architecture

## Two-Repo Model

| Repo | Purpose |
|---|---|
| `terraform` (this repo) | Provisions cloud infrastructure: clusters, VPCs, load balancers, DNS, ArgoCD bootstrap |
| `dieubernetes` | GitOps source of truth: what runs on clusters (ApplicationSets, Helm values, app configs) |

Terraform creates clusters and installs ArgoCD. ArgoCD syncs everything else from `dieubernetes`. After bootstrap, Terraform never touches application-layer concerns.

```
terraform apply (platform cluster)
  → DOKS cluster + LB
  → ArgoCD installed via Helm
  → Root ApplicationSet seeded → points at dieubernetes repo
         ↓
  ArgoCD syncs dieubernetes
  → ingress-nginx, cert-manager, external-dns, sealed-secrets
  → Mealie, API, LGTM, Immich (on workload clusters)
```

---

## Directory Structure

```
terraform/
  modules/
    digitalocean/
        doks-cluster/     # Reusable: VPC + DOKS + LB + Project
      database/         # Placeholder — DO managed Postgres/Redis
    aws/
      cluster/          # Future: VPC + EKS
  clusters/
    dieubernetes-do-platform-nyc3/        # Platform cluster infra
    dieubernetes-do-platform-nyc3-argocd/ # ArgoCD on platform cluster
    dieubernetes-do-main-nyc3/            # Workload cluster infra
    dieubernetes-do-main-nyc3-argocd/     # ArgoCD registration (if ever moved)
  shared/
    cloudflare/         # DNS zone + base records
    failover/           # Cloudflare Worker — automatic cluster health + DNS failover
  traffic-control/
    prod/               # Service CNAMEs + active_cluster variable
  homelab/
    unraid/             # Docker provider: Caddy, Immich, Pi-hole
  docs/
```

---

## Cluster Naming

### Format

```
dieubernetes-{provider}-{account}-{region}
```

| Segment | Examples | Notes |
|---|---|---|
| `provider` | `do`, `aws` | Cloud provider slug |
| `account` | `platform`, `main`, `spare`, `exp` | Stable alias — not the budget amount |
| `region` | `nyc3`, `ams3`, `use1` | Provider region slug; AWS regions abbreviated |

### Examples

```
dieubernetes-do-platform-nyc3    # permanent platform cluster — hosts ArgoCD
dieubernetes-do-main-nyc3        # primary workload cluster
dieubernetes-do-spare-ams3       # second DO account, Amsterdam
dieubernetes-aws-main-use1       # AWS main account, us-east-1 (future)
```

This name is used **identically** in every system:
```
Cloudflare DNS:    dieubernetes-do-main-nyc3.dieu.dev
TFC workspace:     dieubernetes-do-main-nyc3
ArgoCD cluster:    dieubernetes-do-main-nyc3
Terraform dir:     clusters/dieubernetes-do-main-nyc3/
dieubernetes dir:  clusters/dieubernetes-do-main-nyc3/
```

### Why budget stays out of the name

Budget (`$200`, `free`) changes over time. Encode it as a cluster label instead.

---

## Cluster Tiers

Two tiers — expressed as labels in `dieubernetes/clusters/{name}/cluster.yaml`:

| Tier | Cluster | What runs there |
|---|---|---|
| `platform` | `dieubernetes-do-platform-nyc3` | ArgoCD only — managed by Terraform, not dieubernetes |
| `workload` | everything else | Full stack: all apps, LGTM, ingress, cert-manager |

Currently everything runs on every workload cluster (no economy tier yet). Add a `tier: economy` label later when you want a cheap cluster that skips heavy apps like LGTM.

### Cluster labels schema

```yaml
# dieubernetes/clusters/dieubernetes-do-main-nyc3/cluster.yaml
labels:
  provider: digitalocean
  account: main
  region: nyc3
  tier: workload
  budget: "200"
```

ApplicationSets in `dieubernetes` use these labels to decide what gets deployed where:

```yaml
# Deploy everything to all workload clusters
generators:
  - clusters:
      selector:
        matchLabels:
          tier: workload
```

---

## Planned Applications

All apps deploy to every `tier: workload` cluster via ApplicationSets in `dieubernetes`.

### Infrastructure layer (every cluster)
| App | Purpose |
|---|---|
| gateway-api-crds | Gateway API CRDs (installed before controllers, cloud-agnostic) |
| Envoy Gateway | Gateway API implementation — adopts the pre-provisioned LB via `EnvoyProxy` annotations |
| cert-manager | TLS certificates via Let's Encrypt (DNS-01 via Cloudflare) |
| external-dns | Writes service-level DNS records to Cloudflare |
| external-secrets | Syncs secrets from 1Password via ESO |
| kube-prometheus-stack | Prometheus + Alertmanager, remote-writes to Grafana Cloud |
| KEDA | Event-driven autoscaling |
| OpenCost | In-cluster cost tracking per namespace/workload, exports to Prometheus |

All routing uses Gateway API (`HTTPRoute`) — no `Ingress` resources. Envoy Gateway is cloud-agnostic; the pre-provisioned LB is adopted via cloud-specific annotations on the `EnvoyProxy` resource:

| Cloud | Pre-provision | Annotation |
|---|---|---|
| DigitalOcean | `digitalocean_loadbalancer` | `do-loadbalancer-id` |
| GKE | Reserve static IP | `networking.gke.io/load-balancer-ip-address` |
| EKS | Allocate Elastic IPs | `aws-load-balancer-eip-allocations` |

### Platform layer (platform cluster only)
| App | Purpose |
|---|---|
| Kargo | GitOps promotion — stage → prod cluster via ArgoCD |
| Argo Rollouts | Pod-level canary via Gateway API HTTPRoute weights (future) |

### Application layer (every workload cluster)
| App | URL | Notes |
|---|---|---|
| Portfolio | `dieu.dev`, `www.dieu.dev` | Personal portfolio site. Static or SSR. |
| api.dieu.dev | `api.dieu.dev` | Portfolio content API — projects, work history. Go service. |
| overengineered.dieu.dev | `overengineered.dieu.dev` | Live cluster dashboard — calls `status.dieu.dev` Worker for infra data, `api.dieu.dev` for content. |
| Mealie | `recipes.dieu.dev` | Recipe manager. Postgres backend. |
| Plausible | `analytics.dieu.dev` | Privacy-first web analytics. Postgres backend. |
| changedetection.io | `changes.dieu.dev` | Web page change monitoring. |

`api.dieu.dev` serves portfolio/personal content only — it runs on the cluster and can tolerate being unavailable during a cluster outage. Infrastructure status data (cluster health, costs, failover history) is served by `status.dieu.dev`, a Cloudflare Worker that is always available regardless of cluster state.

### Cost tracking

| Tool | What it tracks | Where |
|---|---|---|
| Infracost | Estimated cost delta per Terraform PR | GitHub Actions (`.github/workflows/infracost.yml`) |
| OpenCost | Actual cost per namespace/workload | In-cluster, metrics in Grafana Cloud |
| DO billing API | Actual spend per cluster (via DO Projects) | Queried by `status.dieu.dev` Worker |
| Workers KV ledger | Manual entries for non-API costs (1Password, domains) | `overengineered.dieu.dev` UI |

Lifetime spend = sum of all DO invoices (billing API) + KV ledger entries. The failover Worker snapshots monthly spend to KV so the lifetime total is preserved even if DO invoice history is ever unavailable.

### Shared Postgres

Mealie and Plausible both need Postgres. Rather than a sidecar DB per app, a single shared Postgres instance serves all apps that need it — one database per app, one instance to maintain.

Options (decide when provisioning):
- **CloudNativePG operator** — runs Postgres in-cluster, managed via a Kubernetes CRD. Free, portable across clusters. Needs a PV for storage; migration = `pg_dump`/`pg_restore`.
- **DO Managed Database** — Postgres lives outside all clusters (~$15/mo smallest tier). Survives cluster switches without any migration. Worth it once you're switching clusters regularly.

Start with CloudNativePG (free, no extra cost). Migrate to DO Managed Database when the first cluster switch makes the migration story annoying.

### Prometheus alerting rules
`samber/awesome-prometheus-alerts` provides a curated library of Prometheus alerting rules. Pull relevant rules (k8s, Envoy Gateway, Postgres, etc.) into `dieubernetes` as `PrometheusRule` resources rather than writing them from scratch.

---

## ArgoCD Topology

**One ArgoCD instance, permanently on the platform cluster.** It manages all other clusters as registered targets.

```
dieubernetes-do-platform-nyc3 (platform)
  └── ArgoCD
        ├── manages → dieubernetes-do-main-nyc3
        ├── manages → dieubernetes-do-spare-ams3  (future)
        └── manages → dieubernetes-aws-main-use1  (future)
```

The platform cluster is sized small (`s-2vcpu-4gb`, 1 node, ~$24/mo) and never destroyed. `argocd.dieu.dev` always points at the platform cluster LB.

### Why not per-cluster ArgoCD

Per-cluster ArgoCD means each cluster is self-contained, but cross-cluster concerns (ApplicationSets targeting multiple clusters, a unified UI) become impossible. The platform cluster solves this permanently and cheaply.

### Changing the platform cluster

If the platform cluster ever needs to move (DO account issue, region change):
1. Bootstrap ArgoCD on the new cluster: `terraform apply clusters/new-platform-argocd/`
2. New ArgoCD syncs from `dieubernetes` — identical state within minutes (git is the source of truth)
3. Re-register all managed clusters: `argocd cluster add ...`
4. Switch `argocd.dieu.dev` DNS to new cluster
5. Destroy old: `terraform destroy clusters/old-platform-argocd/`

ArgoCD has no state of its own — its source of truth is the `dieubernetes` git repo.

---

## DNS Architecture

### Layer 1 — Cluster subdomains (permanent)

One A record per cluster. Exists as long as the cluster exists. Used to verify a cluster before switching traffic.

```
dieubernetes-do-platform-nyc3.dieu.dev  A → platform LB IP  (proxied)
dieubernetes-do-main-nyc3.dieu.dev      A → workload LB IP  (proxied)
```

### Layer 2 — Service CNAMEs (the traffic switch)

All workload CNAMEs point at the active cluster subdomain. Flipping `active_cluster` moves all of them atomically.

```
# Pinned — never switch with traffic-control
argocd.dieu.dev           CNAME → dieubernetes-do-platform-nyc3.dieu.dev

# Workload — controlled by active_cluster in traffic-control/prod/
dieu.dev                  CNAME → dieubernetes-do-main-nyc3.dieu.dev
www.dieu.dev              CNAME → dieubernetes-do-main-nyc3.dieu.dev
api.dieu.dev              CNAME → dieubernetes-do-main-nyc3.dieu.dev
overengineered.dieu.dev   CNAME → dieubernetes-do-main-nyc3.dieu.dev
recipes.dieu.dev          CNAME → dieubernetes-do-main-nyc3.dieu.dev
analytics.dieu.dev        CNAME → dieubernetes-do-main-nyc3.dieu.dev
changes.dieu.dev          CNAME → dieubernetes-do-main-nyc3.dieu.dev

# Cloudflare Worker routes — never point at a cluster, always available
status.dieu.dev           → Cloudflare Worker (cluster health, costs, failover state)

# Cloudflare Pages — static, not cluster-hosted
docs.dieu.dev             → Cloudflare Pages (platform documentation, future)
```

`status.dieu.dev` is a Cloudflare Worker route, not a DNS CNAME — it resolves independently of any cluster. `overengineered.dieu.dev` calls it for infrastructure data so the dashboard stays up even during a cluster outage.

Managed in `traffic-control/prod/`. One variable controls all workload service routing:

```hcl
variable "active_cluster" {
  default = "dieubernetes-do-main-nyc3"
}
```

Cloudflare proxies all records — CNAME flattening handles the apex, switching is instant.

### DNS flow

```
User → recipes.dieu.dev
  → Cloudflare resolves CNAME → dieubernetes-do-main-nyc3.dieu.dev → LB IP
  → DO Load Balancer
  → Envoy Gateway (routes on Host: recipes.dieu.dev via HTTPRoute)
  → Mealie pod
```

---

## Cluster Failover

Automatic failover is handled by a **Cloudflare Worker** (`shared/failover/`) deployed via Terraform. It runs on Cloudflare's infrastructure — independent of any cluster — so it survives a total cluster failure.

### How it works

```
Worker cron (every 60s)
  → GET https://dieubernetes-do-main-nyc3.dieu.dev/healthz
  → 3 consecutive failures?
    → Cloudflare API: flip all service CNAMEs → standby cluster subdomain
    → Discord/webhook notification: "failover triggered — active: dieubernetes-do-stage-nyc3"
```

Since all service CNAMEs are proxied, the flip is instant — no TTL to wait on.

### Cluster tiers and failover targets

With stage and prod clusters both running, failover targets are deterministic:

```
prod active     stage active
      ↕  (failover)  ↕
dieubernetes-do-main-nyc3   →   dieubernetes-do-stage-nyc3
```

The Worker reads the current `active_cluster` from a KV store (written by `dieuctl traffic switch`) and flips to the next cluster in the priority list.

### Recovery

Failover is automatic; recovery is manual. After the original cluster is healthy:

```bash
dieuctl traffic switch --to dieubernetes-do-main-nyc3
```

This prevents flap (automatic failback on first healthy response) and gives you a chance to verify the cluster before returning traffic.

### status.dieu.dev API

The Worker also handles HTTP requests at `status.dieu.dev`, exposing infrastructure state for `overengineered.dieu.dev`. Since it runs on Cloudflare — not the cluster — it responds even during a full cluster outage.

```
GET status.dieu.dev/clusters        → list of clusters + health + tier
GET status.dieu.dev/active          → current active_cluster
GET status.dieu.dev/costs           → current month spend per cluster (DO billing API)
GET status.dieu.dev/costs/lifetime  → all-time spend (DO invoices + KV ledger)
GET status.dieu.dev/failover        → failover history from KV
```

### Terraform resources (`shared/failover/`)

```hcl
resource "cloudflare_worker_script" "failover" { ... }
resource "cloudflare_worker_cron_trigger" "failover" {
  schedules = ["*/1 * * * *"]   # every minute
}
resource "cloudflare_workers_kv_namespace" "failover_state" { ... }
```

The Worker uses the same `CLOUDFLARE_API_TOKEN` as the rest of the Cloudflare workspace — no new credentials needed.

---

## State Layout

TFC org: `dieubernetes`. Each layer may read outputs from layers below.

```
Workspace                              Directory                         Reads from
──────────────────────────────────────────────────────────────────────────────────────
dieubernetes-do-platform-nyc3          clusters/dieubernetes-do-platform-nyc3/
dieubernetes-do-platform-nyc3-argocd   clusters/dieubernetes-do-platform-nyc3-argocd/  → platform cluster
dieubernetes-do-main-nyc3              clusters/dieubernetes-do-main-nyc3/
cloudflare                             shared/cloudflare/                → traffic-control-prod
traffic-control-prod                   traffic-control/prod/             → all cluster workspaces
failover                               shared/failover/                  → all cluster workspaces
homelab-unraid                         homelab/unraid/
```

### TFC credential variable sets

| Variable Set | Contains | Used by |
|---|---|---|
| `do-main-creds` | `DIGITALOCEAN_TOKEN` for main account | `dieubernetes-do-*-nyc3` workspaces |
| `do-spare-creds` | `DIGITALOCEAN_TOKEN` for spare account | `dieubernetes-do-spare-*` workspaces |
| `cloudflare-creds` | `CLOUDFLARE_API_TOKEN`, account ID | `cloudflare`, `traffic-control-prod`, `failover` |
| `homelab-creds` | Docker host address, SSH key | `homelab-unraid` |

Swapping which DO account a cluster bills to = swap the variable set on that TFC workspace.

### Apply order for a fresh environment

```
1. clusters/dieubernetes-do-platform-nyc3/
2. clusters/dieubernetes-do-platform-nyc3-argocd/
3. clusters/dieubernetes-do-main-nyc3/
   → register with ArgoCD: argocd cluster add dieubernetes-do-main-nyc3
4. traffic-control/prod/
5. shared/cloudflare/
```

---

## Stamping Out a New Cluster

### Terraform

```bash
cp -r clusters/dieubernetes-do-main-nyc3 clusters/dieubernetes-do-spare-ams3

# Edit clusters/dieubernetes-do-spare-ams3/main.tf:
#   name   = "dieubernetes-do-spare-ams3"
#   region = "ams3"
#   min_nodes, max_nodes  ← tune for budget

# Edit clusters/dieubernetes-do-spare-ams3/backend.tf:
#   workspaces { name = "dieubernetes-do-spare-ams3" }
```

Create TFC workspace `dieubernetes-do-spare-ams3`, assign `do-spare-creds` variable set.

```bash
cd clusters/dieubernetes-do-spare-ams3
terraform init && terraform apply
```

### dieubernetes

```bash
cp -r clusters/dieubernetes-do-main-nyc3 clusters/dieubernetes-do-spare-ams3

# Edit cluster.yaml:
#   account: spare
#   region: ams3
#   budget: "200"

# Edit values/ingress-nginx.yaml:
#   update do-loadbalancer-id annotation with lb_id from terraform output
```

Push to `dieubernetes` → ArgoCD syncs all apps onto the new cluster.

### Register and verify

```bash
argocd cluster add dieubernetes-do-spare-ams3
# Verify apps are syncing, then test on cluster subdomain:
curl -H "Host: recipes.dieu.dev" https://dieubernetes-do-spare-ams3.dieu.dev
```

---

## Switching Traffic Between Clusters

```
1. New cluster fully running + all apps synced by ArgoCD
2. Migrate stateful data (see below)
3. Verify on cluster subdomain
4. Change active_cluster in TFC workspace traffic-control-prod:
     active_cluster = "dieubernetes-do-spare-ams3"
5. terraform apply  →  all service CNAMEs flip atomically
6. Monitor (10-15 min)
7a. Healthy → destroy old cluster
7b. Unhealthy → revert active_cluster, apply (instant rollback)
```

### Stateful data migration

| Service | Data | Migration |
|---|---|---|
| Mealie | SQLite/Postgres — recipes | Built-in backup export → import on new cluster |
| Immich | Postgres — photo metadata | `pg_dump` → `pg_restore` on new cluster. Photos stay on Unraid — no migration needed. |
| Grafana | Dashboards | Stored as code in `dieubernetes` — no migration, ArgoCD provisions them |
| Loki | Logs | Pointed at DO Spaces — survives any cluster switch automatically |

Store Grafana dashboards as JSON in `dieubernetes/charts/grafana/dashboards/` from day one. ArgoCD provisions them on every cluster via Grafana's sidecar. This removes Grafana from the migration list entirely.

---

## Adding a New Cloud Provider

1. Create `modules/aws/cluster/` with the same output interface:
   ```
   Required outputs: cluster_endpoint, cluster_ca_certificate,
                     cluster_token, kubeconfig, lb_ip, lb_id, vpc_id
   ```
2. Create `clusters/dieubernetes-aws-main-use1/` calling the new module
3. Register the new cluster with ArgoCD on the platform cluster
4. `traffic-control/prod/` and `shared/cloudflare/` are provider-agnostic — they consume outputs without caring whether the cluster is DOKS or EKS

---

## Homelab (Unraid)

| Concern | Approach |
|---|---|
| Provisioning | `homelab/unraid/` via `kreuzwerker/docker` Terraform provider |
| Remote access | Tailscale — no open ports on home router |
| DNS | Pi-hole on Unraid handles `*.home.dieu.dev` → local IPs. No Cloudflare records. |
| Public exposure | None |

Services managed as Docker containers on Unraid:
- **Caddy** — local reverse proxy, routes `*.home.dieu.dev` to containers
- **Pi-hole** — local DNS, split DNS for homelab subdomains
- **Immich** — photo management + ML inference (runs on Unraid CPU, photos on NAS storage)

Immich is on Unraid (not the cluster) because photos live on NAS storage — moving them to cloud block storage would be expensive and slow. ML inference runs on Unraid's CPU; initial indexing runs overnight, incremental processing is fast enough regardless.
