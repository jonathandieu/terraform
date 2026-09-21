terraform {
  cloud {
    organization = "dieubernetes"
    workspaces {
      name = "failover"
    }
  }
}
