
variable "instance" {
  type = object({
    min_count              = number
    max_count              = number
    termination_protection = string
    managed_scaling_status = string
    protect_from_scale_in  = bool
  })
  default = {
    min_count               = 1
    max_count               = 1
    termination_protection  = "DISABLED"
    managed_scaling_status  = "ENABLED"
    protect_from_scale_in   = false
    scaling_target_capacity = 95
  }
}

variable "node" {
  type = map(any)
  default = {
    t3micro = {
      instance_type     = "t3.micro"
      weighted_capacity = 1
    }
  }
}

variable "capacity_name" {
  type    = string
  default = "DRONE_MICRO"
}

variable "capacity_count" {
  type    = number
  default = 1
}

variable "network" {
  type = object({
    vpc_id              = string
    vpc_public_subnets  = list(string)
    vpc_private_subnets = list(string)
    cluster_name        = string
    cluster_id          = string
  })
}

variable "task_cpu" {
  description = "CPU of Fargate taskalue"
  default     = 2048
  type        = number
}

variable "task_memory" {
  description = "Memory of Fargate task"
  default     = 829
  type        = number
}

variable "runner_version" {
  default = "v1.6.3"
  type    = string
}

variable "runner_port" {
  default = 3000
  type    = number
}

variable "runner_capacity" {
  type = number
}

variable "runner_debug" {
  type    = string
  default = "true"
}

variable "server_security_group" {
  type = string
}

variable "service_discovery_dns_namespace_id" {
  type = string
}

variable "service_discovery_dns_namespace_name" {
  type = string
}

variable "log_group_id" {
  type = string
}

variable "service_discovery_server_endpoint" {
  type = string
}