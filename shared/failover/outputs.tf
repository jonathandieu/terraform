output "kv_namespace_id" {
  description = "KV namespace ID — used by dieuctl to seed initial cluster state"
  value       = cloudflare_workers_kv_namespace.state.id
}

output "worker_name" {
  value = cloudflare_workers_script.failover.script_name
}

output "status_url" {
  value = "https://status.${var.cloudflare_zone_name}"
}
