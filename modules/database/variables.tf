variable "db_identifier" {
  description = "Unique identifier of rds instance"
}

variable "db_storage" {
  description = "Engine type"
}

variable "db_engine" {
  default     = "postgres"
  description = "Engine type"
}

variable "db_engine_version" {
  description = "Engine version"

  default = {
    postgres = "10.6"
  }
}

variable "db_engine_port" {
  description = "Engine version"

  default = {
    postgres = 5432
  }
}

variable "db_instance_class" {
  description = "Instance class"
}

variable "db_name" {
  description = "Database Name"
}

variable "db_username" {
  description = "Database user name"
}

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

variable "ci_server_app_security_group_id" {
  description = "Security group id of application"
}

