variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "zone_name" {
  description = "Cloudflare zone name"
  type        = string
  default     = "dieu.dev"
}

variable "primary_cluster_workspace" {
  description = "TFC workspace name of the active platform cluster — apex and argocd DNS point at its lb_ip"
  type        = string
}
