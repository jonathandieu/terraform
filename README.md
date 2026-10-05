# terraform

Infrastructure-as-code for dieu.dev: DOKS clusters, Cloudflare DNS/email, failover Worker.

## Layout

```
clusters/          # TFC workspaces — platform / prod / stage DOKS (atl1)
modules/           # reusable modules (doks-cluster)
shared/cloudflare  # dieu.dev DNS + email routing
shared/failover    # status Worker
digitalocean/init  # Spaces bootstrap (Loki + reserved tfstate bucket; manual only)
scripts/           # withsecrets.sh → op run
```

## Apply path

TFC org `dieubernetes`, **local** execution. State in TFC; plans/applies run in CI (or locally via `withsecrets.sh`).

| Event | What runs |
|-------|-----------|
| PR | `fmt` / `validate` / `tflint`, then `plan` for changed workspaces |
| merge to `main` | `apply` for changed workspaces (serial) |

`digitalocean/init` is not in the apply matrix (no remote backend).

### GitHub Actions secrets

| Secret | Used for |
|--------|----------|
| `TF_TOKEN_app_terraform_io` | TFC API (state + workspace vars) |
| `DIGITALOCEAN_TOKEN` | DOKS / Spaces provider |
| `CLOUDFLARE_API_TOKEN` | Cloudflare provider |
| `TF_VAR_argocd_admin_password_bcrypt` | platform ArgoCD helm (if not already a TFC terraform var) |

Without these, validate still runs; plan/apply fail closed.

### Local

```bash
cp .env.tpl.example .env.tpl   # fill op:// refs
cd clusters/dieubernetes-stage-do-atl1
../../scripts/withsecrets.sh terraform init
../../scripts/withsecrets.sh terraform plan
```

## Cluster naming

`dieubernetes-{tier}-{provider}-{region}` — e.g. `dieubernetes-platform-do-atl1`.

ArgoCD cluster secret `name` / label short form: `{tier}-{provider}-{region}` (`platform-do-atl1`).
