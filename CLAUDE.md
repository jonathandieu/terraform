# terraform

Infrastructure-as-code for dieu.dev. Manages DOKS clusters, Cloudflare DNS/email, and the failover Worker.

## Repos

| Repo | Purpose |
|------|---------|
| `terraform/` | This repo — infrastructure provisioning |
| `dieubernetes/` | GitOps manifests (ArgoCD ApplicationSets, Helm charts) |
| `dieuctl/` | CLI for cluster lifecycle and secret management |

## Running Terraform

Prefer merge-to-main CI apply (`.github/workflows/terraform.yml`). Locally, always run through `withsecrets.sh`:

```bash
scripts/withsecrets.sh terraform plan
scripts/withsecrets.sh terraform apply
```

## Secrets

Vault `1Password`, titles `{provider}.{kind}`, token field `credential`.

- `TF_TOKEN_app_terraform_io` — `op://1Password/HCP Terraform/credential`
- `DIGITALOCEAN_TOKEN` — DO API token
- `CLOUDFLARE_API_TOKEN` — Cloudflare zone/account token
- `TF_VAR_argocd_admin_password_bcrypt` — ArgoCD admin bcrypt hash

## TFC

- Org: `dieubernetes`
- Execution mode: **local** (CLI or GitHub Actions; state in TFC)
- One workspace per applyable root, named to match the directory (except `shared/cloudflare` → workspace `cloudflare`, `shared/failover` → `failover`)

## Cluster naming

`dieubernetes-{tier}-{provider}-{region}`

ArgoCD secret name uses the short form `{tier}-{provider}-{region}` (e.g. `platform-do-atl1`).

## Terraform version

Pinned to `1.15.6` via `.terraform-version`.
