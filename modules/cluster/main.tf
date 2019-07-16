locals {
  sub_domain           = var.ci_sub_domain
  root_domain          = var.root_domain
  server_log_group_arn = var.server_log_group_arn
  agent_log_group_arn  = var.agent_log_group_arn
  vpc_id               = var.vpc_id
  keypair_name         = var.keypair_name
}

resource "aws_ecs_cluster" "ci_server" {
  name = var.cluster_name
}

resource "aws_autoscaling_group" "ci_server_drone_agent" {
  name                 = "ci-server-drone-agent"
  vpc_zone_identifier  = var.private_subnets
  min_size             = var.min_instances_count
  max_size             = var.max_instances_count
  desired_capacity     = var.min_instances_count
  launch_configuration = aws_launch_configuration.ci_server_app.name

  tags = [
    {
      key                 = "Name"
      value               = "${local.sub_domain}.${local.root_domain}"
      propagate_at_launch = true
    },
  ]
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*-x86_64-ebs"]
  }
}

resource "aws_launch_configuration" "ci_server_app" {
  security_groups = [
    aws_security_group.ci_server_ecs_instance.id,
  ]

  key_name             = local.keypair_name
  image_id             = data.aws_ami.amazon_linux_2.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ci_server.name
  user_data            = templatefile("${path.module}/templates/cloud-config.yml", { ecs_cluster_name = aws_ecs_cluster.ci_server.name })

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = var.ec2_volume_size
  }
}

resource "aws_iam_instance_profile" "ci_server" {
  role = aws_iam_role.drone_agent.name
}

resource "aws_iam_role_policy" "ec2" {
  role = aws_iam_role.drone_agent.name
  policy = templatefile("${path.module}/templates/cluster-instance.json", { server_log_group_arn = local.server_log_group_arn, agent_log_group_arn = local.agent_log_group_arn })
}

resource "aws_security_group" "ci_server_ecs_instance" {
  description = "Restrict access to application instances"
  vpc_id = local.vpc_id
  name = "ci-server-ecs-instance-sg"
}

resource "aws_security_group_rule" "ci_server_ecs_instance_egress" {
  type = "egress"
  description = "RDP a"
  depends_on = [aws_security_group.ci_server_ecs_instance]
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ci_server_ecs_instance.id
}

resource "aws_security_group_rule" "ci_server_ecs_instance_ingress" {
  type = "ingress"
  description = "RDP b"
  depends_on = [aws_security_group.ci_server_ecs_instance]
  protocol = "tcp"
  from_port = 22
  to_port = 22

  cidr_blocks = var.ip_access_whitelist

  security_group_id = aws_security_group.ci_server_ecs_instance.id
}

resource "aws_iam_role" "drone_agent" {
  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}