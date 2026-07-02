terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "cloudflare"
    }
  }
}
