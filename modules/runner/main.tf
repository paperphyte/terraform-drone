locals {
  container_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/"
}

#-----------------------------------
# Security Group rules for runner
#-----------------------------------
resource "aws_security_group" "runner" {
  description = "Restrict access to drone_runner."
  vpc_id      = lookup(var.network, "vpc_id")
  name        = "drone-runner-sg"
}

resource "aws_security_group_rule" "runner_default_egress" {
  type              = "egress"
  description       = "Outgoing service traffic rule"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.runner.id
}

#-----------------------------------
# Access from Drone runner to server
#-----------------------------------

resource "aws_security_group_rule" "runner_ingress" {
  type        = "ingress"
  description = "Drone CI/CD runner instances to access"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80

  source_security_group_id = aws_security_group.runner.id
  security_group_id        = var.server_security_group
}

#-----------------------------------
# Cluster Role Policies
#-----------------------------------

resource "aws_iam_role" "ecs_instance" {
  name = "${lower(var.capacity_name)}-ecs-instance-role"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com", "spotfleet.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${lower(var.capacity_name)}_ecs_instance_profile"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role       = aws_iam_role.ecs_instance.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_spotfleetscale_role" {
  role       = aws_iam_role.ecs_instance.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetAutoscaleRole"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_cloudwatch_role" {
  role       = aws_iam_role.ecs_instance.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_ecr_role" {
  role       = aws_iam_role.ecs_instance.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

#-----------------------------------
# Cluster Instance Creation
#-----------------------------------


resource "aws_autoscaling_group" "provider" {
  wait_for_capacity_timeout = 0
  vpc_zone_identifier       = var.network["vpc_private_subnets"]
  max_size                  = lookup(var.instance, "max_count", 1)
  min_size                  = lookup(var.instance, "min_count", 1)
  protect_from_scale_in     = lookup(var.instance, "protect_from_scale_in", null)
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
      spot_max_price                           = ""
      spot_instance_pools                      = 1
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.spot_instance.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.node
        content {
          instance_type     = override.value.instance_type
          weighted_capacity = override.value.weighted_capacity
        }
      }
    }
  }

  tag {
    key                 = "Name"
    value               = "${lower(var.capacity_name)}-tasks"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "provider" {

  name = upper(var.capacity_name)
  # complains about autoscaling group scale-in otherwise
  depends_on = [aws_autoscaling_group.provider]

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.provider.arn
    managed_termination_protection = lookup(var.instance, "termination_protection", "DISABLED")

    managed_scaling {
      maximum_scaling_step_size = 4
      minimum_scaling_step_size = 1
      status                    = lookup(var.instance, "managed_scaling_status", "ENABLED")
      target_capacity           = lookup(var.instance, "scaling_target_capacity", 95)
    }
  }
}


resource "aws_launch_template" "spot_instance" {

  image_id      = data.aws_ami.amazon_linux_2.id
  ebs_optimized = false
  instance_type = "t3.micro"
  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.runner.id]

  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yml", {
    cluster_name         = lookup(var.network, "cluster_name", null)
    reserved_memory      = 128
    enable_spot_draining = true
  }))
}

#-----------------------------------
# Runner Task Initiation
#-----------------------------------


module "drone_runner_task" {
  service_name                       = "${lower(var.capacity_name)}-runner"
  source                             = "../task"
  vpc_id                             = lookup(var.network, "vpc_id", null)
  vpc_private_subnets                = var.network["vpc_private_subnets"]
  task_name                          = "drone-${lower(var.capacity_name)}-runner"
  task_image                         = "drone/drone-runner-docker"
  task_image_version                 = var.runner_version
  task_container_log_group_name      = var.log_group_id
  container_registry                 = local.container_registry
  service_discovery_dns_namespace_id = var.service_discovery_dns_namespace_id
  service_cluster_name               = var.network["cluster_name"]
  service_cluster_id                 = var.network["cluster_id"]
  task_bind_port                     = var.runner_port
  task_requires_compatibilities      = "EC2"
  service_capacity_provider          = var.capacity_name
  mount_points = [{
    containerPath = "/var/run/docker.sock"
    sourceVolume  = "dockersock"
    readOnly      = true
  }]
  volumes = [
    {
      name                     = "dockersock"
      host_path                = "/var/run/docker.sock"
      efs_volume_configuration = []
    }
  ]
  task_environment_vars = [
    {
      name  = "DRONE_RUNNER_LABELS"
      value = "instance:${lower(replace(var.capacity_name, "DRONE_", ""))}"
    },
    {
      name  = "DRONE_RUNNER_NAME"
      value = "runner-${lower(replace(var.capacity_name, "DRONE_", ""))}"
    },
    {
      name  = "DRONE_RPC_PROTO"
      value = "http"
    },
    {
      name  = "DRONE_RUNNER_CAPACITY"
      value = tostring(var.runner_capacity)
    },
    {
      name  = "DRONE_TRACE"
      value = var.runner_debug
    },
    {
      name  = "DRONE_RPC_DUMP_HTTP"
      value = var.runner_debug
    },
    {
      name  = "DRONE_RPC_DUMP_HTTP_BODY"
      value = var.runner_debug
    },
    {
      name  = "DRONE_DEBUG",
      value = var.runner_debug
    },
    {
      name  = "DRONE_DOCKER_STREAM_PULL"
      value = var.runner_debug
    },
    {
      name  = "DRONE_RPC_DEBUG"
      value = var.runner_debug
    },
    {
      name  = "DRONE_RPC_HOST"
      value = var.service_discovery_server_endpoint
    },
    {
      name  = "DRONE_SECRET_PLUGIN_ENDPOINT"
      value = "http://${var.service_discovery_secret_endpoint}:3000"
    }
  ]
  task_secret_vars = [
    {
      name      = "DRONE_RPC_SECRET"
      valueFrom = data.aws_ssm_parameter.rpc_secret.arn
    },
    {
      name      = "DRONE_SECRET_PLUGIN_TOKEN"
      valueFrom = data.aws_ssm_parameter.secret_secret.arn
    }
  ]
}

resource "aws_security_group_rule" "server_runner_task_ingress" {
  type        = "ingress"
  description = "Drone CI/CD runner tasks to access"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80

  source_security_group_id = module.drone_runner_task.service_sg_id
  security_group_id        = var.server_security_group
}

resource "aws_security_group_rule" "secret_runner_task_ingress" {
  type        = "ingress"
  description = "Drone CI/CD runner tasks to access"
  protocol    = "tcp"
  from_port   = 3000
  to_port     = 3000

  source_security_group_id = module.drone_runner_task.service_sg_id
  security_group_id        = var.secrets_security_group
}
