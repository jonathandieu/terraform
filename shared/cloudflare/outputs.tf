output "zone_id" {
  value = data.cloudflare_zone.main.id
}

output "zone_name" {
  value = data.cloudflare_zone.main.name
}
