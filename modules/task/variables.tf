variable "vpc_id" {
  description = "ID of vpc"
  type        = string
}

variable "vpc_private_subnets" {
  description = "Private subnets to create task in"
  type        = list(string)
}

variable "lb_target_group_id" {
  description = "Id of specific target group"
  type        = string
}

variable "task_name" {
  description = "Name of task containeralue"
  type        = string
}

variable "task_image" {
  description = "Name of task container image"
  type        = string
}

variable "task_image_version" {
  description = "Version of task container image"
  default     = "latest"
  type        = string
}

variable "task_cpu" {
  description = "CPU of Fargate taskalue"
  default     = 256
  type        = number
}

variable "task_memory" {
  description = "Memory of Fargate task"
  default     = 512
  type        = number
}

variable "task_container_cpu" {
  description = "cpu of Fargate task container"
  default     = 256
  type        = number
}

variable "task_container_memory" {
  description = "memory of Fargate task container"
  default     = 512
  type        = number
}

variable "task_requires_compatibilities" {
  description = "Define task type for compatibilities"
  default     = "FARGATE"
  type        = string
}

variable "task_container_log_group_name" {
  description = "Name of log group for container"
  type        = string
}

variable "task_min_count" {
  description = "Minimum number of task containers"
  default     = 1
  type        = number
}

variable "task_max_count" {
  description = "Maximum number of task containers"
  default     = 1
  type        = number
}

variable "task_bind_port" {
  description = "Portmapping of task container port"
  default     = 80
  type        = number
}

variable "task_secret_vars" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "This is a list of maps, where each map should contain `name`, `valueFrom"
  default     = null
}



variable "task_environment_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "This is a list of maps, where each map should contain `name`, `value"
  default     = null
}

variable "service_name" {
  type        = string
  description = "Name of service"
}

variable "service_capacity_provider" {
  type        = string
  description = "Capacity provider of service"
  default     = "FARGATE_SPOT"
}

variable "service_cluster_name" {
  type        = string
  description = "Name of cluster for service"
}

variable "service_cluster_id" {
  type        = string
  description = "ID of cluster for service"
}

variable "service_discovery_dns_namespace_id" {
  type        = string
  description = "Service discovery private dns namespace id"
}

variable "mount_points" {
  type = list(object({
    containerPath = string
    sourceVolume  = string
    readOnly      = bool
  }))

  description = "Container mount points. This is a list of maps, where each map should contain `containerPath`, `sourceVolume` and `readOnly`"
  default     = []
}

variable "volumes" {
  description = "(Optional) A set of volume blocks that containers in your task may use"
  type = list(object({
    name      = string
    host_path = string
    efs_volume_configuration = list(object({
      file_system_id          = string
      root_directory          = string
      transit_encryption      = string
      transit_encryption_port = string
      authorization_config = list(object({
        access_point_id = string
        iam             = string
      }))
    }))
  }))
  default = []
}

variable "load_balancer" {
  description = "One loadbalancer definition in a list"
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "container_registry" {
  type = string
  description = "Registry of container image"
  default = null
}