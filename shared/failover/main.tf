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
    name = var.cloudflare_zone_name
  }
}

# KV namespace — stores cluster health state and routing decisions
resource "cloudflare_workers_kv_namespace" "state" {
  account_id = var.cloudflare_account_id
  title      = "dieubernetes-failover-state"
}

# Worker script — health checks + status API
resource "cloudflare_workers_script" "failover" {
  account_id  = var.cloudflare_account_id
  script_name = "dieubernetes-failover"
  content     = file("${path.module}/worker.js")
  module      = true

  kv_namespace_binding {
    name         = "STATE"
    namespace_id = cloudflare_workers_kv_namespace.state.id
  }

  plain_text_binding {
    name = "CLUSTERS_JSON"
    text = jsonencode(var.clusters)
  }
}

# Cron trigger — health check every minute
resource "cloudflare_workers_cron_trigger" "health_check" {
  account_id  = var.cloudflare_account_id
  script_name = cloudflare_workers_script.failover.script_name
  schedules   = ["* * * * *"]
}

# DNS record for status.dieu.dev — proxied so CF intercepts it for the Worker route
resource "cloudflare_dns_record" "status" {
  zone_id = data.cloudflare_zone.main.id
  name    = "status"
  type    = "A"
  content = "192.0.2.1" # dummy — CF never forwards to this when proxied + route active
  proxied = true
  ttl     = 1
}

# Worker route — status.dieu.dev/* → failover Worker
resource "cloudflare_workers_route" "status" {
  zone_id     = data.cloudflare_zone.main.id
  pattern     = "status.${var.cloudflare_zone_name}/*"
  script_name = cloudflare_workers_script.failover.script_name
}
