terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "dieubernetes-platform-do-atl1"
    }
  }
}
