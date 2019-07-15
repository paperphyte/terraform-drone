variable "cluster_arn" {
  description = "Arn of an ecs cluster"
}

variable "task_domain_name" {
  description = "Public Domain name of target task"
}

variable "route53_hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
}

variable "function_name" {
  description = "The function name of the created lambda"
}

variable "ecs_service_name" {
  description = "The Service name of the ECS task"
}

variable "domain_ttl" {
  description = "TTL for domain records"
  default     = 300
}

variable "log_retention" {
  description = "Retention in days to keep logs"
  default     = 3
}

variable "vpc_arn" {
  description = "arn of vpc"
}

