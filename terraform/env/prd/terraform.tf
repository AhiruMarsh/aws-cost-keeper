terraform {
  cloud {
    organization = "a-marsh_net"

    workspaces {
      name = "costkeeper-prd-workspace"
    }
  }
}