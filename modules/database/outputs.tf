output "root_password" {
  value       = "${random_string.db_password.result}"
  sensitive   = true
  description = "RDS database root user password"
}

output "address" {
  value       = "${aws_db_instance.ci_db.address}"
  description = "Address to RDS DB instance"
}

output "user" {
  value       = "${aws_db_instance.ci_db.username}"
  description = "Database username"
}

output "name" {
  value       = "${aws_db_instance.ci_db.name}"
  description = "Database name"
}

output "port" {
  value       = "${aws_db_instance.ci_db.port}"
  description = "Database Port"
}

output "engine" {
  value       = "${aws_db_instance.ci_db.engine}"
  description = "Engine type"
}
