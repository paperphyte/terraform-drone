locals {
  slave_cpu_alarm_cfg = [
    {
      operator = "GreaterThanOrEqualToThreshold"
      treshold = 95
      action   = aws_appautoscaling_policy.node_scale_up.arn
    },
    {
      operator = "LessThanOrEqualToThreshold"
      treshold = 5
      action   = aws_appautoscaling_policy.node_scale_down.arn
    }
  ]
}

resource "aws_spot_fleet_request" "main" {
  iam_fleet_role                      = aws_iam_role.spotfleet.arn
  spot_price                          = var.bid_price
  allocation_strategy                 = var.allocation_strategy
  target_capacity                     = var.target_capacity
  terminate_instances_with_expiration = true
  valid_until                         = var.valid_until
  replace_unhealthy_instances         = true

  lifecycle {
    ignore_changes = [
      target_capacity
    ]
  }

  dynamic "launch_specification" {
    for_each = var.node_instance_type
    content {
      tags = {
        Name = var.fqdn
      }
      key_name             = var.keypair_name
      ami                  = data.aws_ami.amazon_linux_2.image_id
      iam_instance_profile = aws_iam_instance_profile.ci_server.name
      subnet_id            = var.private_subnets[0]

      spot_price    = launch_specification.value.price
      instance_type = launch_specification.value.name

      root_block_device {
        volume_type = "gp2"
        volume_size = var.ec2_volume_size
      }

      vpc_security_group_ids = [
        aws_security_group.ci_server_ecs_instance.id
      ]

      user_data = templatefile("${path.module}/templates/cloud-config.yml", { ecs_cluster_name = aws_ecs_cluster.ci_server.name })
    }
  }
}

resource "aws_appautoscaling_target" "node" {
  min_capacity       = var.min_node_fleet_requests_count
  max_capacity       = var.max_node_fleet_requests_count
  resource_id        = "spot-fleet-request/${aws_spot_fleet_request.main.id}"
  role_arn           = aws_iam_role.node_fleet_autoscaling.arn
  scalable_dimension = "ec2:spot-fleet-request:TargetCapacity"
  service_namespace  = "ec2"
}

resource "aws_appautoscaling_policy" "node_scale_up" {
  name               = "ci-node-scale_up"
  resource_id        = aws_appautoscaling_target.node.resource_id
  scalable_dimension = aws_appautoscaling_target.node.scalable_dimension
  service_namespace  = aws_appautoscaling_target.node.service_namespace
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    metric_aggregation_type = "Average"
    cooldown                = var.node_scaling_cooldown
    adjustment_type         = "ChangeInCapacity"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "node_scale_down" {
  name               = "ci-node-scale_down"
  resource_id        = aws_appautoscaling_target.node.resource_id
  scalable_dimension = aws_appautoscaling_target.node.scalable_dimension
  service_namespace  = aws_appautoscaling_target.node.service_namespace
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    metric_aggregation_type = "Average"
    cooldown                = var.node_scaling_cooldown
    adjustment_type         = "ChangeInCapacity"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_metric_alarm" {
  count               = length(local.slave_cpu_alarm_cfg)
  alarm_name          = "ci-node-alarm-cpu-${count.index}"
  comparison_operator = lookup(element(local.slave_cpu_alarm_cfg, count.index), "operator")
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2Spot"
  period              = 60
  statistic           = "Average"
  threshold           = lookup(element(local.slave_cpu_alarm_cfg, count.index), "treshold")
  treat_missing_data  = "missing"
  dimensions = {
    FleetRequestId = aws_spot_fleet_request.main.id
  }
  alarm_description = "Autoscaling ci ecs nodes on CPUUtilization"
  alarm_actions     = [lookup(element(local.slave_cpu_alarm_cfg, count.index), "action")]
}