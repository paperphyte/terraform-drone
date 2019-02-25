variable "root_domain" {
  description = "Pre-existing Route53 Hosted Zone domain"
}

variable "ci_sub_domain" {
  description = "Sub part of domain for ci"
}

variable "vpc_id" {
  description = "Id for vpc"
}

variable "subnet_id_1" {
  description = "id for subnet"
}

variable "subnet_id_2" {
  description = "id for subnet"
}

variable "default_ttl" {
  default     = "300"
  description = "Default ttl for domain records"
}

variable "root_domain_zone_id" {
  description = "Pre-existing Route53 Hosted Zone ID"
}

variable "target_health_check_endpoint" {
  default     = "/healthz"
  description = "endpoint for healthcheck target"
}

variable "target_port" {
  description = "target port"
}

variable "target_security_group_id" {
  description = "security group of target"
}
