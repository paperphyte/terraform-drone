output "cluster_instance_security_group_id" {
  value       = "${aws_security_group.ci_server_ecs_instance.id}"
  description = "Security Group ID of cluster instances"
}

output "id" {
  value       = "${aws_ecs_cluster.ci_server.id}"
  description = "Identifier for cluster"
}

output "name" {
  value       = "${aws_ecs_cluster.ci_server.name}"
  description = "Name for cluster"
}
