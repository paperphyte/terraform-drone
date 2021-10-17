output "service_sg_id" {
  value = module.drone_runner_task.service_sg_id
}

output "capacity_name" {
  value = var.capacity_name
}