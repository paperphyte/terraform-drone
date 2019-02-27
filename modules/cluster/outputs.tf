output "instance_security_group_id" {
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

output "ami_image_id" {
  value       = "${data.aws_ami.amazon_linux_2.image_id}"
  description = "Image ID for ec2 cluster instances"
}

output "iam_instance_profile" {
  value       = "${aws_iam_instance_profile.ci_server.name}"
  description = "Instance Profile name of cluster ec2 instances"
}
