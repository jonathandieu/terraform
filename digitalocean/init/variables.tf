variable "do_token" {
  type        = string
  description = "DigitalOcean API token"
}

variable "spaces_access_id" {
  type        = string
  description = "DigitalOcean Spaces access key ID"
  sensitive   = true
}

variable "spaces_secret_key" {
  type        = string
  description = "DigitalOcean Spaces secret access key"
  sensitive   = true
}
