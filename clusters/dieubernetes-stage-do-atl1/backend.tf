terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "dieubernetes-stage-do-atl1"
    }
  }
}
