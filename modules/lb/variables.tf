variable "vpc_id" {
  description = "ID of vpc"
  type        = string
}

variable "vpc_public_subnets" {
  description = "Public subnets to create lb in"
  type        = list(any)
}

variable "dns_root_name" {
  description = "Domain name of root zone such as 'example.com'"
  type        = string
}

variable "dns_hostname" {
  description = "Host name of lb such as 'myhost'"
  type        = string
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
    path                = "/health"
    matcher             = "200"
    timeout             = 30
    interval            = 60
    healthy_threshold   = "3"
    unhealthy_threshold = "2"
  }
}
