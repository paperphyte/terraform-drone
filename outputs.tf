output "ci_server_url" {
  description = "public accessible url of the ci"
  value       = "http://${aws_alb.front.dns_name}"
}

output "ci_db_root_password" {
  value       = "${random_string.ci_db_password.result}"
  sensitive   = true
  description = "RDS database root user password"
}

output "ci_drone_rpc_secret" {
  value       = "${random_string.drone_rpc_secret.id}"
  sensitive   = true
  description = "The RPC secret for drone server"
}
