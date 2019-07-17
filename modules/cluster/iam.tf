resource "aws_iam_role" "node_fleet_autoscaling" {
  name = "node_fleet_autoscaling"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["application-autoscaling.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "node_fleet_autoscaling" {
  name = aws_iam_role.node_fleet_autoscaling.name
  role = aws_iam_role.node_fleet_autoscaling.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "application-autoscaling:RegisterScalableTarget",
              "cloudwatch:DescribeAlarms",
              "ec2:DescribeSpotFleetRequests",
              "ec2:ModifySpotFleetRequest"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "spotfleet" {
  role   = aws_iam_role.spotfleet.name
  policy = file("${path.module}/templates/spot-fleet.json")
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