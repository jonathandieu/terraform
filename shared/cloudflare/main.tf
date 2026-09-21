terraform {
  required_version = ">= 1.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# Configure Cloudflare provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Create DNS zone for your domain
resource "cloudflare_zone" "main" {
  account = var.cloudflare_account_id
  name    = var.domain_name
}

# Create DNS records for production
resource "cloudflare_record" "prod_main" {
  zone_id = cloudflare_zone.main.id
  name    = "@"
  value   = var.prod_load_balancer_ip
  type    = "A"
  ttl     = 300
  proxied = true
}

resource "cloudflare_record" "prod_www" {
  zone_id = cloudflare_zone.main.id
  name    = "www"
  value   = var.domain_name
  type    = "CNAME"
  ttl     = 300
  proxied = true
}

resource "cloudflare_record" "prod_api" {
  zone_id = cloudflare_zone.main.id
  name    = "api"
  value   = var.prod_api_gateway_ip
  type    = "A"
  ttl     = 300
  proxied = true
}

# Create DNS records for staging
resource "cloudflare_record" "stage_main" {
  zone_id = cloudflare_zone.main.id
  name    = "stage"
  value   = var.stage_load_balancer_ip
  type    = "A"
  ttl     = 300
  proxied = true
}

resource "cloudflare_record" "stage_api" {
  zone_id = cloudflare_zone.main.id
  name    = "api-stage"
  value   = var.stage_api_gateway_ip
  type    = "A"
  ttl     = 300
  proxied = true
}

# Configure Cloudflare settings for performance and security
resource "cloudflare_zone_settings_override" "main" {
  zone_id = cloudflare_zone.main.id

  settings {
    ssl                      = "full"
    min_tls_version          = "1.2"
    security_level           = "medium"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    websockets               = "on"
    opportunistic_encryption = "on"
    tls_1_3                  = "on"
    minify {
      css  = "on"
      html = "on"
      js   = "on"
    }
  }
}