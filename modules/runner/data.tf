data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*-x86_64-ebs"]
  }
}

data "aws_ssm_parameter" "rpc_secret" {
  name = "/drone/server/rpc_secret"
}