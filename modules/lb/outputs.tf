output "lb_sg_id" {
  value       = aws_security_group.lb.id
  description = "ID of security group"
}

output "fqdn" {
  value       = "${var.dns_hostname}.${var.dns_root_name}"
  description = "Fully qualified domain name of lb such as 'myhost.example.com'"
}

output "lb_target_group_id" {
  value       = aws_lb_target_group.lb.id
  description = "Target group ID"
}

output "lb_id" {
  value       = aws_lb.lb.id
  description = "Loadbalancer ID"
}
