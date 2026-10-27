terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "spaces"
    }
  }
}
