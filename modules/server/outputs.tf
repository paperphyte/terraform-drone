output "server_sg_id" {
  value = module.drone_server_task.service_sg_id
}

output "rpc_secret" {
  value = random_string.server_secret.result
}