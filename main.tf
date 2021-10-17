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
    "FARGATE", "FARGATE_SPOT", module.defaultrunner.capacity_name
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

module "server" {
  source            = "./modules/server"
  drone_user_filter = var.drone_user_filter
  drone_admin       = var.drone_admin
  log_group_id      = aws_cloudwatch_log_group.drone.id
  network = {
    vpc_id              = module.vpc.vpc_id
    vpc_public_subnets  = module.vpc.public_subnets
    vpc_private_subnets = module.vpc.private_subnets
    cluster_name        = aws_ecs_cluster.cluster.name
    cluster_id          = aws_ecs_cluster.cluster.id
    allow_cidr_range = concat(
      concat(var.allowed_cidr,
      data.github_ip_ranges.ranges.hooks_ipv4),
      ["${element(module.vpc.nat_public_ips, 0)}/32"]
    )
    dns_root_name = var.dns_root_name
    dns_root_id   = var.dns_root_id
  }

  server_versions = {
    server  = var.versions["server"]
    secrets = var.versions["secrets"]
    yaml    = var.versions["yaml"]
  }
}

module "defaultrunner" {
  source = "./modules/runner"
  network = {
    vpc_id              = module.vpc.vpc_id
    vpc_public_subnets  = module.vpc.public_subnets
    vpc_private_subnets = module.vpc.private_subnets
    cluster_name        = aws_ecs_cluster.cluster.name
    cluster_id          = aws_ecs_cluster.cluster.id
  }
  runner_version                       = var.versions["runner"]
  runner_capacity                      = 2
  server_security_group                = module.server.server_sg_id
  secrets_security_group               = module.server.secrets_sg_id
  log_group_id                         = aws_cloudwatch_log_group.drone.id
  service_discovery_dns_namespace_id   = module.server.service_discovery_dns_namespace_id
  service_discovery_dns_namespace_name = module.server.service_discovery_dns_namespace_name
  service_discovery_server_endpoint    = module.server.service_discovery_server_endpoint
  service_discovery_secret_endpoint    = module.server.service_discovery_secret_endpoint
}
