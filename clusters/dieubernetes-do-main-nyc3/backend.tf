terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "dieubernetes-do-main-nyc3"
    }
  }
}
