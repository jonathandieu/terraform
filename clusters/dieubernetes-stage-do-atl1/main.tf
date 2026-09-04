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

# min_nodes=0: DO bills a powered-off GPU droplet same as a running one, so
# scale-to-zero only works if the autoscaler actually destroys the node.
resource "digitalocean_kubernetes_node_pool" "gpu" {
  cluster_id = module.cluster.cluster_id
  name       = "dieubernetes-stage-do-atl1-gpu"
  size       = "gpu-mi300x1-192gb"
  auto_scale = true
  min_nodes  = 0
  max_nodes  = 1
  labels = {
    workload = "gpu"
  }
  taint {
    key    = "nvidia.com/gpu"
    value  = "present"
    effect = "NoSchedule"
  }
  tags = ["dieubernetes", "dieubernetes-stage-do-atl1", "gpu"]
}
