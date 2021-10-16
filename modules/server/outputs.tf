output "server_sg_id" {
  value = module.drone_server_task.service_sg_id
}

output "rpc_secret" {
  value = random_string.server_secret.result
}

output "service_discovery_dns_namespace_id" {
  value = module.drone_lb.service_discovery_private_dns_namespace_id
}

output "service_discovery_dns_namespace_name" {
  value = module.drone_lb.service_discovery_private_dns_namespace_id
}

output "service_discovery_server_endpoint" {
  value = "drone-server.drone.local"
}