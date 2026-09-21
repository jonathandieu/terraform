terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "dieubernetes-do-platform-nyc3"
    }
  }
}
