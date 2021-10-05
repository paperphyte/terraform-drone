variable "drone_user_filter" {
  type        = string
  description = "Optional comma-separated list of accounts. Registration is limited to users in this list, or users that are members of organizations included in this list."
  default     = ""
}

variable "log_group_id" {
  type        = string
  default     = ""
}

variable "network" {
  type = object({
    vpc_id              = string
    vpc_public_subnets  = string
    vpc_private_subnets = bool
    cluster_name        = string
    cluster_id          = string
    allow_cidr_range   = list
    dns_root_name      = string
  })
}

variable "server_versions" {
  type = object({
    server    = string
    secrets   = string
    registry  = string
    monorepo  = string
  })
  default = {
    server  = "v2.4.0"
    secrets = "v1.0.0"
    registry ="v1.0.0"
    monorepo = "v0.4.2"
  }
}
