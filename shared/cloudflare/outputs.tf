output "zone_id" {
  description = "Cloudflare zone ID"
  value       = cloudflare_zone.main.id
}

output "zone_name" {
  description = "Cloudflare zone name"
  value       = cloudflare_zone.main.name
}

output "name_servers" {
  description = "Cloudflare name servers for the zone"
  value       = cloudflare_zone.main.name_servers
}

output "prod_main_record" {
  description = "Production main DNS record"
  value       = cloudflare_record.prod_main.hostname
}

output "stage_main_record" {
  description = "Staging main DNS record"
  value       = cloudflare_record.stage_main.hostname
}