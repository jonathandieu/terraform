resource "digitalocean_kubernetes_cluster" "doks" {
  name    = "doks"
  region  = "tor1"
  version = "1.33.2"
}