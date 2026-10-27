# Log storage for self-hosted Loki (dieubernetes charts/infrastructure/loki).
# Spaces keys are account-wide (not bucket-scoped); provider reads
# DIGITALOCEAN_TOKEN, SPACES_ACCESS_KEY_ID, SPACES_SECRET_ACCESS_KEY.
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

# Metrics storage for self-hosted Mimir (dieubernetes charts/infrastructure/mimir).
resource "digitalocean_spaces_bucket" "mimir" {
  name   = "dieubernetes-mimir"
  region = "nyc3"

  lifecycle_rule {
    id      = "cleanup_old_blocks"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

output "mimir_bucket_name" {
  description = "Name of the Spaces bucket for Mimir metrics storage"
  value       = digitalocean_spaces_bucket.mimir.name
}

output "mimir_bucket_endpoint" {
  description = "Endpoint URL for the Mimir Spaces bucket"
  value       = digitalocean_spaces_bucket.mimir.endpoint
}
