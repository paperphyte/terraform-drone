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

module "server" {
  source            = "./modules/server"
  drone_user_filter = "paperphyte"
  drone_admin       = "krusipo"
  log_group_id      = aws_cloudwatch_log_group.drone.id
  network = {
    vpc_id              = module.vpc.vpc_id
    vpc_public_subnets  = module.vpc.public_subnets
    vpc_private_subnets = module.vpc.private_subnets
    cluster_name        = aws_ecs_cluster.cluster.name
    cluster_id          = aws_ecs_cluster.cluster.id
    allow_cidr_range = concat(
      concat(["95.198.57.109/32"],
      data.github_ip_ranges.ranges.hooks_ipv4),
      ["${element(module.vpc.nat_public_ips, 0)}/32"]
    )
    dns_root_name = var.dns_root_name
    dns_root_id   = var.dns_root_id
  }

  server_versions = {
    server    = "v2.4.0"
    secrets   = "v1.0.0"
    registry  = "v1.0.0"
    monorepo  = "v0.4.2"
    admission = "v1.0.0"
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
  runner_capacity                      = 2
  server_security_group                = module.server.server_sg_id
  log_group_id                         = aws_cloudwatch_log_group.drone.id
  service_discovery_dns_namespace_id   = module.server.service_discovery_dns_namespace_id
  service_discovery_dns_namespace_name = module.server.service_discovery_dns_namespace_name
}
