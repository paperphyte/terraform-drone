data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ssm_parameter" "github_client_id" {
  name = "/drone/github/client_id"
}

data "aws_ssm_parameter" "github_client_secret" {
  name = "/drone/github/client_secret"
}

data "aws_ssm_parameter" "db_user_name" {
  name = "/drone/db/user_name"
}

data "aws_ssm_parameter" "db_password" {
  name = "/drone/db/password"
}

data "aws_ssm_parameter" "yaml_extension_github_token" {
  name = "/drone/github/token"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*-x86_64-ebs"]
  }
}