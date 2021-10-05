# ----------------------------------------
# Drone Server RDS Database
# ----------------------------------------


# ----------------------------------------
# Drone Server
# ----------------------------------------


module "drone_lb" {
  source              = "./modules/lb"
  vpc_id              = lookup(var.network, "vpc_id", null)
  vpc_public_subnets  = lookup(var.network, "vpc_public_subnets", null)
  dns_root_name       = lookup(var.network, "dns_root_name", null)
  dns_hostname        = "drone"
  target_port         = 80
}

resource "aws_security_group_rule" "ssl_ingress" {
  type              = "ingress"
  description       = "Incoming"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = lookup(var.network, "allow_cidr_range", ["0.0.0.0/0"])
  security_group_id = module.drone_lb.lb_sg_id
}

module "drone_server_task" {
  source                        = "../server"
  vpc_id                        = lookup(var.network, "vpc_id", null)
  vpc_private_subnets           = lookup(var.network, "private_subnets", null)
  lb_target_group_id            = module.drone_lb.lb_target_group_id
  task_name                     = "drone-server"
  task_image                    = "drone/drone"
  task_image_version            = lookup(var.server_versions, "server", null)
  task_container_log_group_name = var.log_group_id
  task_bind_port                = 80
  load_balancer = [{
    target_group_arn = module.drone_lb.lb_target_group_id
    container_name   = "drone-server"
    container_port   = 80
  }]

  task_secret_vars = [
    {
      name      = "DRONE_GITHUB_CLIENT_ID"
      valueFrom = data.aws_ssm_parameter.github_client_id.arn
    }
  ]
  task_environment_vars = [
    {
      name  = "DRONE_USER_FILTER"
      value = var.drone_user_filter
    }
  ]
}
