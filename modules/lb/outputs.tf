output "lb_sg_id" {
  value       = aws_security_group.lb.id
  description = "ID of security group"
}

output "fqdn" {
  value       = aws_route53_record.lb_public_url.fqdn
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

output "service_discovery_private_dns_namespace_id" {
  value       = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
  description = "Service discovery private namespace id"
}

output "service_discovery_private_dns_namespace_name" {
  value       = aws_service_discovery_private_dns_namespace.private_dns_namespace.name
  description = "Service discovery private namespace id"
}