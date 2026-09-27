terraform {
  required_version = "~> 1.16.0"

  cloud {
    organization = "a-marsh_net"

    workspaces {
      name = "costkeeper-prd-workspace"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.65.0"
    }
  }
}