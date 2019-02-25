output "drone_agent_log_group_arn" {
  value = "${aws_cloudwatch_log_group.drone_agent.arn}"
}
