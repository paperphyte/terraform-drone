output "rpc_server_url" {
  value       = "http://${aws_service_discovery_service.ci_server.name}.${aws_service_discovery_private_dns_namespace.ci.name}"
  description = "URL of RPC server"
}

output "drone_server_log_group_arn" {
  value = aws_cloudwatch_log_group.drone_server.arn
}

output "ci_server_security_group_id" {
  value = aws_security_group.ci_server_app.id
}

output "service_name" {
  value = "ci-server-drone-server"
}

output "drone_secrets_shared_secret" {
  value = random_id.drone_secrets_shared_secret.hex
}

output "drone_secrets_url" {
  value = "http://${aws_service_discovery_service.drone_secrets.name}.${aws_service_discovery_private_dns_namespace.ci.name}:3000"
}