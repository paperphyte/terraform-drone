
resource "random_id" "drone_secrets_shared_secret" {
  byte_length = 16
}

resource "aws_ecs_task_definition" "drone_secrets" {
  family = "drone-secrets"

  container_definitions = templatefile("${path.module}/templates/secrets-task-definition.json", {
    log_group_drone_secrets    = aws_cloudwatch_log_group.drone_server.name,
    log_group_region           = var.aws_region,
    shared_secret_key          = random_id.drone_secrets_shared_secret.hex,
    container_cpu              = var.fargate_task_cpu,
    container_memory           = var.fargate_task_memory,
    addr = "${aws_service_discovery_service.drone_secrets.name}.${aws_service_discovery_private_dns_namespace.ci.name}"
  })

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  task_role_arn      = aws_iam_role.drone_secrets_ecs_task.arn
  execution_role_arn = aws_iam_role.drone_secrets_ecs_task.arn

  cpu    = var.fargate_task_cpu
  memory = var.fargate_task_memory
  tags = {
    Name = var.fqdn
  }
}


resource "aws_ecs_service" "drone_secrets" {
  name            = "ci-server-drone-secrets"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.drone_secrets.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.drone_secrets.id]
    subnets          = var.private_subnets
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.drone_secrets.arn
  }
}

resource "aws_security_group" "drone_secrets" {
  description = "Restrict access to secrets."
  vpc_id      = var.vpc_id
  name        = "drone-secrets-task-sg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    security_groups = [var.cluster_instance_security_group_id]
  }
}

resource "aws_service_discovery_service" "drone_secrets" {
  name = "secrets"

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

resource "aws_iam_role_policy" "drone_secrets_ecs" {
  role   = aws_iam_role.drone_secrets_ecs_task.name
  policy = templatefile("${path.module}/templates/drone-ecs-secrets.json", { server_log_group_arn = var.agent_log_group_arn, agent_log_group_arn = aws_cloudwatch_log_group.drone_server.arn, })
}

resource "aws_iam_role" "drone_secrets_ecs_task" {
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