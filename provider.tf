provider "aws" {
  version = "~> 1.59.0"
  region  = "${var.aws_region}"
}

provider "random" {
  version = "~> 2.0.0"
}
