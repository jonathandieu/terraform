resource "digitalocean_spaces_bucket" "terraform_state" {
  name   = "terraform-state-do"
  region = "nyc3"

  # Enable versioning for state file safety
  versioning {
    enabled = true
  }

  # Optional: Enable lifecycle rules to manage old versions
  lifecycle_rule {
    id      = "cleanup_old_versions"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

# Output the bucket name and region for use in other configurations
output "state_bucket_name" {
  description = "Name of the Spaces bucket for Terraform state"
  value       = digitalocean_spaces_bucket.terraform_state.name
}

output "state_bucket_region" {
  description = "Region of the Spaces bucket for Terraform state"
  value       = digitalocean_spaces_bucket.terraform_state.region
}

output "state_bucket_endpoint" {
  description = "Endpoint URL for the Spaces bucket"
  value       = digitalocean_spaces_bucket.terraform_state.endpoint
}

# Log storage for self-hosted Loki (dieubernetes charts/infrastructure/loki).
# Uses the same account-wide Spaces access key already configured on this provider
# (var.spaces_access_id/spaces_secret_key) - DO Spaces keys are not bucket-scoped,
# so no separate key resource is needed here.
resource "digitalocean_spaces_bucket" "loki" {
  name   = "dieubernetes-loki"
  region = "nyc3"

  lifecycle_rule {
    id      = "cleanup_old_chunks"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

output "loki_bucket_name" {
  description = "Name of the Spaces bucket for Loki log storage"
  value       = digitalocean_spaces_bucket.loki.name
}

output "loki_bucket_endpoint" {
  description = "Endpoint URL for the Loki Spaces bucket"
  value       = digitalocean_spaces_bucket.loki.endpoint
}
