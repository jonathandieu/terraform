terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "dieubernetes-do-platform-atl1"
    }
  }
}
