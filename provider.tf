
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "prod"
      Project     = "drone"
    }
  }
}