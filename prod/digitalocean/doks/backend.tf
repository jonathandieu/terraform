# Backend configuration for DOKS cluster
# This uses the Spaces bucket created by the init configuration

terraform {
  backend "s3" {
    endpoint                    = "nyc3.digitaloceanspaces.com"
    bucket                      = "terraform-state-prod"
    key                         = "doks/terraform.tfstate"
    region                      = "us-east-1" # Required by S3 backend, but not used
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}

# To use this backend:
# 1. Ensure the Spaces bucket exists (run prod/digitalocean/init first)
# 2. Set your Spaces access keys as environment variables:
#    export SPACES_ACCESS_KEY_ID="your-access-key"
#    export SPACES_SECRET_ACCESS_KEY="your-secret-key"
# 3. Run: terraform init


