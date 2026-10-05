# shared/cloudflare

Cloudflare DNS for `dieu.dev`. State lives in TFC workspace `cloudflare` (org `dieubernetes`, local execution).

## What it manages

- Apex + `www` + `argocd` pointing at the platform cluster LB (`primary_cluster_workspace`)
- Cloudflare Email Routing enablement + MX records
- Combined SPF (Cloudflare inbound + Google outbound) and DMARC

Workload hostnames like `preview.dieu.dev` stay with external-dns in dieubernetes.

## Apply

```bash
cd shared/cloudflare
../../scripts/withsecrets.sh terraform init
../../scripts/withsecrets.sh terraform plan
../../scripts/withsecrets.sh terraform apply
```

On `main`, GitHub Actions applies changed workspaces after merge (see `.github/workflows/terraform.yml`).

## First-time import

If MX/SPF/DMARC already exist from the Cloudflare dashboard, import before the first apply:

```bash
terraform import cloudflare_dns_record.mx_route1 <zone_id>/<record_id>
# …same for mx_route2, mx_route3, spf, dmarc
```

Enable **Email Routing** in the Cloudflare dashboard for the zone if it is not already on.
