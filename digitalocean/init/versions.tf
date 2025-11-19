terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.69.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token

  # Spaces credentials (required for Spaces operations)
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}
