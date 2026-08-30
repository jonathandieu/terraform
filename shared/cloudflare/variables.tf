variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "domain_name" {
  description = "Your domain name (e.g., example.com)"
  type        = string
}

variable "prod_load_balancer_ip" {
  description = "Production load balancer IP address"
  type        = string
  default     = ""
}

variable "prod_api_gateway_ip" {
  description = "Production API gateway IP address"
  type        = string
  default     = ""
}

variable "stage_load_balancer_ip" {
  description = "Staging load balancer IP address"
  type        = string
  default     = ""
}

variable "stage_api_gateway_ip" {
  description = "Staging API gateway IP address"
  type        = string
  default     = ""
}