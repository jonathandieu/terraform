terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "dieubernetes-prod-do-atl1"
    }
  }
}
