terraform {
  required_version = ">= 1.10"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

module "cluster" {
  source = "../../modules/digitalocean/doks-cluster"

  name                      = "dieubernetes-stage-do-atl1"
  region                    = "atl1"
  node_size                 = "s-2vcpu-8gb-amd"
  min_nodes                 = 1
  max_nodes                 = 2
  kubernetes_version_prefix = "1.36"
}
