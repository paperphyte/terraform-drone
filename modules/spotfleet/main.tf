locals {
  sub_domain                         = var.ci_sub_domain
  root_domain                        = var.root_domain
  subnet_id_1                        = var.subnet_id_1
  subnet_id_2                        = var.subnet_id_2
  server_log_group_arn               = var.server_log_group_arn
  agent_log_group_arn                = var.agent_log_group_arn
  keypair_name                       = var.keypair_name
  cluster_ami_image_id               = var.cluster_ami_image_id
  cluster_iam_instance_profile       = var.cluster_iam_instance_profile
  cluster_instance_security_group_id = var.cluster_instance_security_group_id
  cluster_name                       = var.cluster_name
  user_data                          = var.cluster_instance_user_data
}

data "template_file" "spotfleet_profile" {
  count    = var.cluster_spot_instance_enabled
  template = file("${path.module}/templates/spot-fleet.json")

  vars = {
    server_log_group_arn = local.server_log_group_arn
    agent_log_group_arn  = local.agent_log_group_arn
  }
}

resource "aws_iam_role" "spotfleet" {
  count = var.cluster_spot_instance_enabled
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
        "Service": ["ec2.amazonaws.com", "spotfleet.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "spotfleet" {
  count = var.cluster_spot_instance_enabled
  role = aws_iam_role.spotfleet[0].name
  policy = data.template_file.spotfleet_profile[0].rendered
}

resource "aws_spot_fleet_request" "main" {
  count = var.cluster_spot_instance_enabled
  iam_fleet_role = aws_iam_role.spotfleet[0].arn
  spot_price = var.bid_price
  allocation_strategy = var.allocation_strategy
  target_capacity = var.target_capacity
  terminate_instances_with_expiration = true
  valid_until = var.valid_until
  replace_unhealthy_instances = true

  launch_specification {
    tags = {
      "Name" = "${local.sub_domain}.${local.root_domain}"
    }
    key_name = local.keypair_name
    ami = local.cluster_ami_image_id
    iam_instance_profile = local.cluster_iam_instance_profile
    subnet_id = "${local.subnet_id_1},${local.subnet_id_2}"

    instance_type = var.instance_type

    root_block_device {
      volume_type = "gp2"
      volume_size = var.ec2_volume_size
    }

    vpc_security_group_ids = [
      local.cluster_instance_security_group_id,
    ]

    user_data = local.user_data
  }
}

