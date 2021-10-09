
variable "instance" {
  type = {
    min_count              = number
    max_count              = number
    termination_protection = string
    managed_scaling_status = string
    protect_from_scale_in  = bool
  }
  default = {
    min_count              = 1
    max_count              = 1
    termination_protection = "DISABLED"
    managed_scaling_status = "ENABLED"
    protect_from_scale_in  = false
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

variable "runner_label" {
  type    = string
  default = "instance:micro"
}

variable "network" {
  type = object({
    vpc_id              = string
    vpc_public_subnets  = string
    vpc_private_subnets = bool
    cluster_name        = string
    cluster_id          = string
  })
}