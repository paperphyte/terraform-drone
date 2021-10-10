module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  cidr                   = "10.0.0.0/16"
  azs                    = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets         = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

resource "aws_cloudwatch_log_group" "drone" {
  name = "drone-cluster"
}

resource "aws_ecs_cluster" "cluster" {
  name = "drone-cluster"
  capacity_providers = [
    "FARGATE", "FARGATE_SPOT"
  ]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.drone.name
      }
    }
  }
}


