# DigitalOcean Kubernetes Service (DOKS) Cluster

terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  # Token can be provided via DIGITALOCEAN_TOKEN environment variable
  # or via a variable if preferred
}

resource "digitalocean_kubernetes_cluster" "doks" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version

  node_pool {
    name       = var.node_pool_name
    size       = var.node_size
    node_count = var.node_count
  }
}


