variable "drone_user_filter" {
  type        = string
  description = "Optional comma-separated list of accounts. Registration is limited to users in this list, or users that are members of organizations included in this list."
  default     = ""
}

variable "drone_admin" {
  type        = string
  description = "User account created on start up."
  default     = ""
}

variable "log_group_id" {
  type    = string
  default = ""
}

variable "drone_debug" {
  type    = string
  default = "false"
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

variable "server_versions" {
  type = object({
    server  = string
    secrets = string
    yaml    = string
  })
  default = {
    server  = "v2.4.0"
    secrets = "v1.0.0"
    yaml    = "v0.4.2"
  }
}

variable "db" {
  type = object({
    port           = number
    name           = string
    instance_class = string
  })
  default = {
    port           = 5432
    name           = "drone"
    instance_class = "db.t3.micro"
  }
}
