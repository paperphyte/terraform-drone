locals {
  container_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/"
}

#-----------------------------------
# Security Group rules for runner
#-----------------------------------
resource "aws_security_group" "runner" {
  description = "Restrict access to drone_runner."
  vpc_id      = local.vpc_id
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
  description = "Drone CI/CD build agents to access"
  protocol    = "tcp"
  from_port   = var.runner_port
  to_port     = var.runner_port

  source_security_group_id = aws_security_group.runner.id
  security_group_id        = var.server_security_group_id
}

#-----------------------------------
# Cluster Role Policies
#-----------------------------------

resource "aws_iam_role" "ecs_instance" {
  name = "${var.name}-ecs-instance-role"
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
  name = "${var.name}_ecs_instance_profile"
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
  vpc_zone_identifier       = lookup(var.network, "private_subnets", null)
  max_size                  = lookup(var.instance, "max_count", null)
  min_size                  = lookup(var.instance, "min_count", null)
  protect_from_scale_in     = var.protect_from_scale_in
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
    value               = "${var.name}-tasks"
    propagate_at_launch = true
  }
}


resource "aws_launch_template" "spot_instance" {

  image_id      = data.aws_ami.amazon_linux_2.id
  ebs_optimized = false
  instance_type = "t3.medium"
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
    file_system_id_01    = join("", var.efs_id)
    efs_directory        = "/mnt/efs"
  }))
}

#-----------------------------------
# Runner Task Initiation
#-----------------------------------

module "drone_runner_task" {
  source                             = "../task"
  vpc_id                             = lookup(var.network, "vpc_id", null)
  vpc_private_subnets                = lookup(var.network, "private_subnets", null)
  lb_target_group_id                 = null
  task_name                          = "drone-${lower(var.capacity_name)}-runner"
  task_image                         = "drone/drone-runner-docker"
  task_image_version                 = var.runner_version
  task_container_log_group_name      = var.log_group_id
  container_registry                 = local.container_registry
  service_discovery_dns_namespace_id = var.service_discovery_dns_namespace_id
  service_cluster_name               = lookup(var.network, "cluster_name", null)
  service_cluster_id                 = lookup(var.network, "cluster_id", null)
  task_bind_port                     = 80
}