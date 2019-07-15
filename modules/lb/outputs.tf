output "target_group_arn" {
  value = join("", aws_alb_target_group.ci_server.*.id)
}

output "load_balancer_security_group_id" {
  value = join("", aws_security_group.ci_server_web.*.id)
}

output "ci_server_url" {
  value = "https"
}

