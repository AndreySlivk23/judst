terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
    http = {
      version = "~> 3.0"
      source  = "hashicorp/http"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }
  required_version = "~> 1.0"
}
