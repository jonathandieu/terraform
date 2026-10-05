variable "zone_name" {
  description = "Cloudflare zone name"
  type        = string
  default     = "dieu.dev"
}

variable "primary_cluster_workspace" {
  description = "TFC workspace of the active platform cluster — apex and argocd DNS use its lb_ip"
  type        = string
  default     = "dieubernetes-platform-do-atl1"
}

variable "dmarc_policy" {
  description = "DMARC TXT value for _dmarc.<zone>"
  type        = string
  default     = "v=DMARC1; p=none; rua=mailto:dmarc@dieu.dev"
}
