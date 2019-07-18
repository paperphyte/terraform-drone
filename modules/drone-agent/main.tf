resource "aws_cloudwatch_log_group" "drone_agent" {
  name = "drone/agent"
  tags = {
    Name = var.fqdn
  }
}

resource "random_pet" "drone_task_runnner_name" {
  separator = "."
}

resource "aws_ecs_task_definition" "drone_agent" {
  family = "drone-agent"
  container_definitions = templatefile("${path.module}/templates/task-definition.json", {
    log_group_region            = var.aws_region,
    log_group_drone_agent       = aws_cloudwatch_log_group.drone_agent.name,
    runner_name                 = random_pet.drone_task_runnner_name.id,
    drone_rpc_server            = var.rpc_server,
    drone_rpc_secret            = var.rpc_secret,
    drone_version               = var.app_version,
    container_cpu               = var.container_cpu,
    container_memory            = var.container_memory,
    drone_logs_debug            = var.app_debug
    drone_secrets_shared_secret = var.drone_secrets_shared_secret
    drone_secrets_url           = var.drone_secrets_url
  })

  volume {
    name      = "dockersock"
    host_path = "/var/run/docker.sock"
  }

  tags = {
    Name = var.fqdn
  }
}

resource "aws_ecs_service" "drone_agent" {
  name = "drone-agent"

  depends_on = [aws_ecs_task_definition.drone_agent]

  cluster         = var.cluster_id
  desired_count   = var.min_container_count
  task_definition = aws_ecs_task_definition.drone_agent.arn
}

locals {
  agent_cpu_alarm_cfg = [
    {
      operator = "GreaterThanOrEqualToThreshold"
      treshold = 95
      action   = aws_appautoscaling_policy.agent_scale_up.arn
    },
    {
      operator = "LessThanOrEqualToThreshold"
      treshold = 5
      action   = aws_appautoscaling_policy.agent_scale_down.arn
    }
  ]
}

resource "aws_cloudwatch_metric_alarm" "cpu_metric_alarm" {
  count               = length(local.agent_cpu_alarm_cfg)
  alarm_name          = "ci-agent-alarm-cpu-${count.index}"
  comparison_operator = lookup(element(local.agent_cpu_alarm_cfg, count.index), "operator")
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = lookup(element(local.agent_cpu_alarm_cfg, count.index), "treshold")

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = aws_ecs_service.drone_agent.name
  }

  alarm_description = "Autoscaling ci ecs agents on CPUUtilization"
  alarm_actions     = [lookup(element(local.agent_cpu_alarm_cfg, count.index), "action")]
}

resource "aws_appautoscaling_target" "drone_agent" {
  min_capacity       = var.min_container_count
  max_capacity       = var.max_container_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.drone_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = aws_iam_role.agent_scaling.arn
}


resource "aws_appautoscaling_policy" "agent_scale_up" {
  name               = "drone-agent-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.drone_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "agent_scale_down" {
  name               = "drone-agent-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.drone_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_iam_role" "agent_scaling" {
  name               = "drone-agent-scaling"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "agent_scaling" {
  role = aws_iam_role.agent_scaling.name
  policy_arn = aws_iam_policy.agent_scaling.arn
}

resource "aws_iam_policy" "agent_scaling" {
  name = "${aws_iam_role.agent_scaling.name}-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:DescribeAlarms"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}