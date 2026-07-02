terraform {
  required_version = ">= 1.10"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "cloudflare" {}

data "cloudflare_zone" "main" {
  filter = {
    name = var.zone_name
  }
}

data "terraform_remote_state" "primary_cluster" {
  backend = "remote"
  config = {
    organization = "dieubernetes"
    workspaces = { name = var.primary_cluster_workspace }
  }
}

locals {
  lb_ip = data.terraform_remote_state.primary_cluster.outputs.lb_ip
}

# Apex A — proxied; always derived from primary cluster state, never hardcoded
resource "cloudflare_dns_record" "apex" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  type    = "A"
  content = local.lb_ip
  proxied = true
  ttl     = 1
}

# www CNAME → apex
resource "cloudflare_dns_record" "www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www"
  type    = "CNAME"
  content = var.zone_name
  proxied = true
  ttl     = 1
}

# argocd — not proxied so cert-manager HTTP-01 challenges reach the cluster directly
resource "cloudflare_dns_record" "argocd" {
  zone_id = data.cloudflare_zone.main.id
  name    = "argocd"
  type    = "A"
  content = local.lb_ip
  proxied = false
  ttl     = 1
}
