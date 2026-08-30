# DigitalOcean Spaces bucket for Terraform state storage
resource "digitalocean_spaces_bucket" "terraform_state" {
  name   = "terraform-state-${var.environment}"
  region = var.region

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

  # Optional: Enable CORS if you need web access
  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET", "HEAD", "POST", "PUT", "DELETE"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
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

