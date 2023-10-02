terraform {
  cloud {
    organization = "alex-sitiy-organization"

    workspaces {
      name = "hello-world-lambda"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}