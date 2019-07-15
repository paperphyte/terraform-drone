locals {
  sub_domain  = var.ci_sub_domain
  root_domain = var.root_domain
  rpc_server  = var.rpc_server
  rpc_secret  = var.rpc_secret
}

resource "aws_cloudwatch_log_group" "drone_agent" {
  name = "drone/agent"
  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "random_pet" "drone_task_runnner_name" {
  separator = "."
}

data "template_file" "drone_agent_task_definition" {
  template = file("${path.module}/templates/task-definition.json")

  vars = {
    log_group_region      = var.aws_region
    log_group_drone_agent = aws_cloudwatch_log_group.drone_agent.name
    runner_name           = random_pet.drone_task_runnner_name.id
    drone_rpc_server      = local.rpc_server
    drone_rpc_secret      = local.rpc_secret
    drone_version         = var.app_version
    container_cpu         = var.container_cpu
    container_memory      = var.container_memory
    drone_logs_debug      = var.app_debug
  }
}

resource "aws_ecs_task_definition" "drone_agent" {
  family                = "drone-agent"
  container_definitions = data.template_file.drone_agent_task_definition.rendered

  volume {
    name      = "dockersock"
    host_path = "/var/run/docker.sock"
  }

  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_ecs_service" "drone_agent" {
  name = "drone-agent"

  depends_on = [aws_ecs_task_definition.drone_agent]

  cluster         = var.cluster_id
  desired_count   = var.max_container_count
  task_definition = aws_ecs_task_definition.drone_agent.arn
}

resource "aws_appautoscaling_target" "drone_agent" {
  max_capacity       = var.max_container_count
  min_capacity       = var.min_container_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.drone_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

