provider "aws" {
  version = "~> 1.59.0"
  region  = "${var.aws_region}"
}

provider "random" {
  version = "~> 2.0.0"
}

provider "template" {
  version = "~> 2.0"
}

provider "archive" {
  version = "~> 1.1"
}
