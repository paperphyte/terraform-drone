provider "aws" {
  version = "~> 2.19.0"
  region  = var.aws_region
}

provider "random" {
  version = "~> 2.1.2"
}

provider "template" {
  version = "~> 2.1.2"
}

provider "archive" {
  version = "~> 1.2.2"
}

