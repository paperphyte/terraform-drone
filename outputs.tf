output "ci_server_url" {
  description = "public accessible url of the ci"
  value       = "${module.load_balancer.url_443}"
}

output "ci_db_root_password" {
  value       = "${module.ci_db.root_password}"
  sensitive   = true
  description = "RDS database root user password"
}

output "ci_drone_rpc_secret" {
  value       = "${random_string.drone_rpc_secret.id}"
  sensitive   = true
  description = "The RPC secret for drone server"
}
