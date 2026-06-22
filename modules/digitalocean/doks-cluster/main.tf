terraform {
  required_version = ">= 1.10"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

data "digitalocean_kubernetes_versions" "main" {
  version_prefix = "${var.kubernetes_version_prefix}."
}

resource "digitalocean_kubernetes_cluster" "main" {
  name    = var.name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.main.latest_version

  node_pool {
    name       = "${var.name}-pool"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes
    tags       = ["dieubernetes", var.name]
  }

  maintenance_policy {
    day        = "sunday"
    start_time = "04:00"
  }

  surge_upgrade = true
}

# Pre-provisioned load balancer — ingress-nginx adopts this via the
# service.beta.kubernetes.io/do-loadbalancer-id annotation so the
# IP is stable and known before ingress is deployed.
resource "digitalocean_loadbalancer" "main" {
  name   = "${var.name}-lb"
  region = var.region

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "tcp"
    target_port     = 80
    target_protocol = "tcp"
  }

  # ingress-nginx takes ownership of forwarding rules and healthchecks
  # after adoption — ignore drift from those fields.
  lifecycle {
    ignore_changes = [
      forwarding_rule,
      healthcheck,
      sticky_sessions,
    ]
  }
}

resource "digitalocean_project" "main" {
  name        = var.name
  description = var.project_description
  purpose     = "Web Application"
  environment = "Production"
}

resource "digitalocean_project_resources" "main" {
  project = digitalocean_project.main.id
  resources = [
    digitalocean_kubernetes_cluster.main.urn,
    digitalocean_loadbalancer.main.urn,
  ]
}
