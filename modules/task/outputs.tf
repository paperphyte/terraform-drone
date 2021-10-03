output "task_role_arn" {
  description = "Role arn for task capabilities"
  value       = aws_iam_role.ecs_task_role.arn
}

output "service_sg_id" {
  description = "ID of security group"
  value       = aws_security_group.service_sg.id
}
