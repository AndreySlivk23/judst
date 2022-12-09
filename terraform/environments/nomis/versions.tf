terraform {
  required_providers {
    aws = {
      version = "~> 4.9"
      source  = "hashicorp/aws"
    }

    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }

    github = {
      version = "~> 4.28.0"
      source  = "integrations/github"
    }
    random = {
      version = "3.4.3"
      source  = "hashicorp/random"
    }
  }
  required_version = "~> 1.0"
}
