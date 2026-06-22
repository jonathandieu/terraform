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

  name                      = "dieubernetes-do-main-nyc3"
  region                    = "nyc3"
  node_size                 = "s-2vcpu-4gb"
  min_nodes                 = 1
  max_nodes                 = 3
  kubernetes_version_prefix = "1.33"
  project_description       = "Primary workload cluster"
}
