variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "DigitalOcean region for the Spaces bucket"
  type        = string
  default     = "nyc3"

  validation {
    condition = contains([
      "nyc3", "ams3", "sgp1", "sfo3", "fra1", "tor1", "blr1", "lon1"
    ], var.region)
    error_message = "Region must be a valid DigitalOcean region."
  }
}