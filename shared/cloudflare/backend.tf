# Terraform Cloud Backend Configuration

terraform {
  backend "remote" {
    organization = "dieu"
    workspaces {
      name = "cloudflare"
    }
  }
}
