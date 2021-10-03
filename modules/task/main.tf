# ----------------------------------------
# AWS IAM Role
# ----------------------------------------
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.task_name}_ecs_task_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ----------------------------------------
# AWS IAM Role Policy
# ----------------------------------------
resource "aws_iam_policy" "task_ssm_policy" {
  name = "${var.task_name}_task_ssm_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "*",
       "Condition": {
          "StringEquals": {
              "kms:EncryptionContext:PARAMETER_ARN":"arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${upper(var.task_name)}_*"
          }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_kms" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = aws_iam_policy.task_ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_ssm_read" {
  role       = aws_iam_role.ecs_task_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ----------------------------------------
# AWS Security Group
# ----------------------------------------
resource "aws_security_group" "service_sg" {
  description = "Restrict access to service."
  vpc_id      = var.vpc_id
  name        = "${var.task_name}-service-sg"
}

resource "aws_security_group_rule" "service_default_egress" {
  type              = "egress"
  description       = "Outgoing service traffic rule"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.service_sg.id
}

# ----------------------------------------
# AWS Task Definition
# ----------------------------------------
resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.service_name
  requires_compatibilities = [var.task_requires_compatibilities]
  network_mode             = "awsvpc"

  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_role.arn

  cpu    = var.task_cpu
  memory = var.task_memory
  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)
      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id          = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", [])
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }
    }
  }
  container_definitions = jsonencode([{
    name   = var.task_name
    image  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.task_image}:${var.task_image_version}"
    cpu    = var.task_container_cpu
    memory = var.task_container_memory
    mountPoints = length(var.mount_points) > 0 ? [
      for mount_point in var.mount_points : {
        containerPath = lookup(mount_point, "containerPath")
        sourceVolume  = lookup(mount_point, "sourceVolume")
        readOnly      = tobool(lookup(mount_point, "readOnly", false))
      }
    ] : var.mount_points
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-stream-prefix = "/${var.task_name}"
        awslogs-group         = var.task_container_log_group_name
        awslogs-region        = data.aws_region.current.name
      }
    }
    portMappings = [
      {
        containerPort = var.task_bind_port
        protocol      = "tcp"
      }
    ]
    secrets     = var.task_secret_vars
    environment = var.task_environment_vars
  }])
}

# ----------------------------------------
# AWS ECS Service Discovery
# ----------------------------------------
resource "aws_service_discovery_service" "discovery_service" {
  name = var.service_name

  dns_config {
    namespace_id = var.service_discovery_dns_namespace_id

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

# ----------------------------------------
# AWS Servie
# ----------------------------------------
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.service_cluster_id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.task_max_count
  capacity_provider_strategy {
    capacity_provider = var.service_capacity_provider
    weight            = 1
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.service_sg.id]
    subnets          = var.vpc_private_subnets
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer
    content {
      target_group_arn = load_balancer.value["target_group_arn"]
      container_name   = load_balancer.value["container_name"]
      container_port   = load_balancer.value["container_port"]
    }
  }

  service_registries {
    registry_arn = aws_service_discovery_service.discovery_service.arn
  }
}

resource "aws_appautoscaling_target" "ecs_service" {
  min_capacity       = var.task_min_count
  max_capacity       = var.task_max_count
  resource_id        = "service/${var.service_cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [
    aws_ecs_service.service
  ]
}
