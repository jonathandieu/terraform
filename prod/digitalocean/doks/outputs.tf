output "cluster_id" {
  description = "ID of the DOKS cluster"
  value       = digitalocean_kubernetes_cluster.doks.id
}

output "cluster_name" {
  description = "Name of the DOKS cluster"
  value       = digitalocean_kubernetes_cluster.doks.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the Kubernetes API server"
  value       = digitalocean_kubernetes_cluster.doks.endpoint
}

output "cluster_status" {
  description = "Status of the DOKS cluster"
  value       = digitalocean_kubernetes_cluster.doks.status
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = digitalocean_kubernetes_cluster.doks.version
}

output "kubeconfig" {
  description = "Kubernetes configuration file (sensitive)"
  value       = digitalocean_kubernetes_cluster.doks.kube_config[0].raw_config
  sensitive   = true
}


