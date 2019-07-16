locals {
  sub_domain  = var.ci_sub_domain
  root_domain = var.root_domain

  db_host_name = var.db_host_name
  db_user      = var.db_user
  db_password  = var.db_password
  db_engine    = var.db_engine
  db_port      = var.db_port

  cluster_name = var.cluster_name
  cluster_id   = var.cluster_id
  vpc_id       = var.vpc_id

  rpc_secret                         = var.rpc_secret
  cluster_instance_security_group_id = var.cluster_instance_security_group_id
  ip_access_whitelist                = var.ip_access_whitelist
}

resource "aws_cloudwatch_log_group" "drone_server" {
  name = "drone/server"
  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

data "template_file" "drone_server_task_definition" {
  template = file("${path.module}/templates/task-definition.json")

  vars = {
    log_group_region          = var.aws_region
    drone_rpc_server          = "${var.ci_sub_domain}.${var.root_domain}"
    log_group_drone_server    = aws_cloudwatch_log_group.drone_server.name
    drone_rpc_secret          = local.rpc_secret
    db_host_name              = local.db_host_name
    db_user                   = local.db_user
    db_password               = local.db_password
    db_engine                 = local.db_engine
    db_port                   = local.db_port
    drone_version             = var.app_version
    drone_logs_debug          = var.app_debug
    drone_server_port         = var.app_port
    container_cpu             = var.fargate_task_cpu
    container_memory          = var.fargate_task_memory
    drone_github_client       = var.env_github_client
    drone_github_secret       = var.env_github_secret
    drone_admin               = var.env_drone_admin
    drone_github_organization = var.env_drone_github_organization
    drone_webhook_list        = var.env_drone_webhook_list
    drone_repository_filter   = var.env_drone_repo_filter
    drone_agents_enabled      = var.env_drone_agents_enabled
    drone_auto_cert           = var.env_drone_auto_cert
    drone_server_proto        = var.env_drone_server_proto
    drone_auto_cert_port      = var.drone_auto_cert_port
    drone_http_ssl_redirect   = var.env_drone_http_ssl_redirect
  }
}

resource "aws_ecs_task_definition" "drone_server" {
  family                   = "drone-server"
  container_definitions    = data.template_file.drone_server_task_definition.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  task_role_arn      = aws_iam_role.ci_server_ecs_task.arn
  execution_role_arn = aws_iam_role.ci_server_ecs_task.arn

  cpu    = var.fargate_task_cpu
  memory = var.fargate_task_memory
  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_ecs_service" "drone_server" {
  name            = "ci-server-drone-server"
  cluster         = local.cluster_id
  task_definition = aws_ecs_task_definition.drone_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_ecs_task_definition.drone_server]

  network_configuration {
    security_groups  = [aws_security_group.ci_server_app.id]
    subnets          = var.public_subnets
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ci_server.arn
  }

}

resource "aws_appautoscaling_target" "ecs_drone_server" {
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.drone_server.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_service_discovery_private_dns_namespace" "ci" {
  name        = "${local.sub_domain}${var.service_discovery_private_namespace}"
  description = "Private DNS ci-server"
  vpc         = local.vpc_id
}

resource "aws_service_discovery_service" "ci_server" {
  name = "drone"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ci.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 10
  }
}


resource "aws_iam_role" "ci_server_ecs_task" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ci_server_ecs" {
  role = aws_iam_role.ci_server_ecs_task.name
  policy = templatefile("${path.module}/templates/drone-ecs.json", { server_log_group_arn = var.agent_log_group_arn, agent_log_group_arn = aws_cloudwatch_log_group.drone_server.arn, })

}

resource "aws_security_group" "ci_server_app" {
  description = "Restrict access to application server."
  vpc_id = local.vpc_id
  name = "ci-server-task-sg"
}

resource "aws_security_group_rule" "ci_server_app_egress" {
  type = "egress"
  description = "RDP c"
  depends_on = [aws_security_group.ci_server_app]
  from_port = 0
  to_port = 0
  protocol = "-1"

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  security_group_id = aws_security_group.ci_server_app.id
}

resource "aws_security_group_rule" "ci_server_app_ingress" {
  type = "ingress"
  description = "Drone CI/CD build agents to access"
  depends_on = [aws_security_group.ci_server_app]
  protocol = "tcp"
  from_port = var.build_agent_port
  to_port = var.build_agent_port

  source_security_group_id = local.cluster_instance_security_group_id
    security_group_id = aws_security_group.ci_server_app.id

}

resource "aws_security_group_rule" "ci_server_app_ingress2" {

  type = "ingress"
  description = "Drone CI/CD User inteface access"
  depends_on = [aws_security_group.ci_server_app]
  protocol = "tcp"
  from_port = var.app_port
  to_port = var.app_port

  cidr_blocks = var.ip_access_whitelist

    security_group_id = aws_security_group.ci_server_app.id

}

resource "aws_security_group_rule" "ci_server_app_ingress3" {
  type = "ingress"
  description = "Drone CI/CD used during autocert"
  depends_on = [aws_security_group.ci_server_app]
  protocol = "tcp"
  from_port = var.drone_auto_cert_port
  to_port = var.drone_auto_cert_port

  cidr_blocks = [
    "0.0.0.0/0",
  ]

    security_group_id = aws_security_group.ci_server_app.id

}

