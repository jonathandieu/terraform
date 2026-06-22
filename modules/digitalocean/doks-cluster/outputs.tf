output "cluster_id" {
  description = "DOKS cluster ID"
  value       = digitalocean_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "DOKS cluster name"
  value       = digitalocean_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = digitalocean_kubernetes_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_token" {
  description = "Kubernetes service account token — expires ~1h, use doctl to refresh for local use"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].token
  sensitive   = true
}

output "kubeconfig" {
  description = "Raw kubeconfig — sensitive, expires ~1h"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive   = true
}

output "lb_ip" {
  description = "Load balancer public IP — consumed by traffic-control and cloudflare workspaces"
  value       = digitalocean_loadbalancer.main.ip
}

output "lb_id" {
  description = "Load balancer ID — used in ingress-nginx do-loadbalancer-id annotation"
  value       = digitalocean_loadbalancer.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.main.id
}

output "project_id" {
  description = "DigitalOcean project ID"
  value       = digitalocean_project.main.id
}
