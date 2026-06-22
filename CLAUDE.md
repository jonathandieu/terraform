# terraform

Infrastructure-as-code for dieu.dev. Manages DOKS clusters, Cloudflare DNS, and Cloudflare Workers.

## Repos in this project

| Repo | Purpose |
|---|---|
| `terraform/` | This repo — infrastructure provisioning |
| `dieubernetes/` | GitOps manifests (ArgoCD ApplicationSets, Helm charts) |
| `dieuctl/` | CLI tool for cluster lifecycle and secret management |

## Running Terraform

Always run through `withsecrets.sh` — it uses `op run` to inject secrets from 1Password:

```bash
scripts/withsecrets.sh terraform plan
scripts/withsecrets.sh terraform apply
```

Never run `terraform apply` directly — secrets won't be present and DO/Cloudflare calls will fail.

## Secret management

Secrets live in 1Password vault `1Password`. Referenced via `op://` URIs in `.env.tpl`.

- `TF_TOKEN_app_terraform_io` — HCP Terraform API token (`op://1Password/HCP Terraform/credential`)
- `DIGITALOCEAN_TOKEN` — DO personal account by default; comment/uncomment in `.env.tpl` to switch accounts
- `CLOUDFLARE_API_TOKEN` — Cloudflare zone token
- `TF_VAR_argocd_admin_password_bcrypt` — bcrypt hash of ArgoCD admin password (item ID `7kzpyj4bxzd7ha4csiaeh3eb2e`, field `bcrypt_hash`)

The ArgoCD plaintext password is stored separately at `op://1Password/ArgoCD Admin/password`.

## TFC setup

- Org: `dieubernetes`
- Execution mode: **local** — plans and applies run on your machine, state stored in TFC
- No variable sets needed — all secrets injected via `withsecrets.sh`
- One TFC workspace per cluster directory, named to match the directory (e.g. `dieubernetes-do-platform-atl1`)

To create a new workspace via API (no UI needed):
```bash
TFC_TOKEN=$(op read "op://1Password/HCP Terraform/credential")
curl -sf \
  --header "Authorization: Bearer $TFC_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{"data":{"type":"workspaces","attributes":{"name":"<workspace-name>","execution-mode":"local"}}}' \
  https://app.terraform.io/api/v2/organizations/dieubernetes/workspaces
```

## Terraform version

Pinned to `1.15.6` via `.terraform-version` (read by asdf). Global `~/.tool-versions` also set to `1.15.6`.

## Cluster naming convention

`dieubernetes-{provider}-{tier}-{region}`

Examples: `dieubernetes-do-platform-atl1`, `dieubernetes-do-stage-atl1`, `dieubernetes-do-main-atl1`

## Cluster layout

Each cluster directory is a thin Terraform root that calls `modules/digitalocean/doks-cluster`:

```
clusters/
  dieubernetes-do-platform-atl1/
    main.tf        # module call + ArgoCD resources (platform only)
    backend.tf     # TFC cloud block
    variables.tf   # argocd_* vars (platform only)
    outputs.tf     # pass-through module outputs
```

Platform clusters include ArgoCD in the same workspace — one `terraform apply` provisions DOKS + installs ArgoCD + seeds the root app + registers the cluster secret. No separate bootstrap step.

The root app-of-apps uses a separate `helm_release "argocd_root"` with the `argocd-apps` chart pinned to `1.6.1`. The 2.0.x line has a confirmed bug where `metadata.name` renders as the list index (`0`) instead of the `name` field — do not upgrade until that is fixed upstream.

## DOKS module

`modules/digitalocean/doks-cluster` provisions: VPC, DOKS cluster, pre-provisioned load balancer (adopted by Envoy Gateway via `do-loadbalancer-id` annotation), DigitalOcean project.

Key outputs: `lb_ip`, `lb_id` (needed for Cloudflare DNS and dieubernetes envoy-gateway override).

## Kubernetes version

Use `kubernetes_version_prefix = "1.36"` (current latest on DOKS). The data source picks the latest patch automatically.

## Region

All clusters use `nyc3` (New York). ATL1 was attempted but DO consistently returned "insufficient capacity" for all valid DOKS slugs. `atl1` remains in the region validation list in case capacity becomes available later.

## bcrypt hash generation

`python3 -c "import bcrypt"` is not available. Use `htpasswd`:

```bash
htpasswd -nbBC 10 "" "$PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/'
```

When passing the hash to `op item create` or `op item edit`, use single quotes or a variable to avoid `$` shell expansion:
```bash
HASH='$2a$10$...'
op item edit <id> "bcrypt_hash=$HASH"
```
