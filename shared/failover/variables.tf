variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_name" {
  description = "Cloudflare zone (domain)"
  type        = string
  default     = "dieu.dev"
}

variable "clusters" {
  description = "Clusters the Worker monitors. Updated by dieuctl when clusters are registered."
  type = list(object({
    name  = string
    lb_ip = string
  }))
  default = []
}
