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

variable "fqdn" {
  description = "Fully qualified domain name of ci"
}

variable "vpc_id" {
  description = "Id for vpc"
}

variable "private_subnets" {
  description = "private subnet ids"
  type        = list
}

variable "public_subnets" {
  description = "public subnet ids"
  type        = list
}

variable "ci_server_app_security_group_id" {
  description = "Security group id of application"
}

