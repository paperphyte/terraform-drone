
resource "aws_iam_role_policy" "spotfleet" {
  role   = aws_iam_role.spotfleet.name
  policy = templatefile("${path.module}/templates/spot-fleet.json", {
    server_log_group_arn = var.server_log_group_arn,
    agent_log_group_arn  = var.agent_log_group_arn
  })
}

resource "aws_spot_fleet_request" "main" {
  iam_fleet_role                      = aws_iam_role.spotfleet.arn
  spot_price                          = var.bid_price
  allocation_strategy                 = var.allocation_strategy
  target_capacity                     = var.target_capacity
  terminate_instances_with_expiration = true
  valid_until                         = var.valid_until
  replace_unhealthy_instances         = true

  launch_specification {
    tags = {
      Name = var.fqdn
    }
    key_name             = var.keypair_name
    ami                  = var.cluster_ami_image_id
    iam_instance_profile = var.cluster_iam_instance_profile
    subnet_id            = var.private_subnets[0]

    instance_type = var.instance_type

    root_block_device {
      volume_type = "gp2"
      volume_size = var.ec2_volume_size
    }

    vpc_security_group_ids = [
      var.cluster_instance_security_group_id,
    ]

    user_data = var.cluster_instance_user_data
  }
}

resource "aws_iam_role" "spotfleet" {
  tags = {
    Name = var.fqdn
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
