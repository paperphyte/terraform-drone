
variable "dns_hostname" {
  description = "Host name of lb such as 'myhost'"
  type        = string
}

variable "network" {
  type = object({
    vpc_id              = string
    vpc_public_subnets  = list(string)
    vpc_private_subnets = list(string)
    cluster_name        = string
    cluster_id          = string
    allow_cidr_range    = list(string)
    dns_root_name       = string
    dns_root_id         = string
  })
}

variable "target_port" {
  description = "Port for target group"
  default     = 80
  type        = number
}

variable "target_health_check" {
  description = "Target health check"
  type        = map(any)
  default = {
    path                = "/healthz"
    matcher             = "200"
    timeout             = 30
    interval            = 60
    healthy_threshold   = "3"
    unhealthy_threshold = "2"
  }
}
