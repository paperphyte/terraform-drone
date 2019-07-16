variable "sub_domain" {
  description = "Sub part of domain for ci"
}

variable "db_host_name" {
}

variable "db_user" {
}

variable "db_password" {
}

variable "db_engine" {
}

variable "db_port" {
}
variable "private_subnets" {
  description = "private subnet ids"
  type        = list
}

variable "public_subnets" {
  description = "public subnet ids"
  type        = list
}

variable "app_version" {
  description = "Current Drone Agent Version"
}

variable "app_debug" {
  description = "Verbose logging of agent communication"
}

variable "app_port" {
  description = "Verbose logging of agent communication"
}

variable "aws_region" {
  description = "The AWS Region"
}

variable "fargate_task_cpu" {
  description = "Fargate task CPU and memory at the task level."
}

variable "fargate_task_memory" {
  description = "Fargate task CPU and memory at the task level."
}

variable "env_github_client" {
  description = "A string containing GitHub oauth Client ID."
}

variable "env_github_secret" {
  description = "A string containing GitHub oauth Client Secret."
}

variable "env_drone_admin" {
  description = "Drone privileged User"
}

variable "env_drone_github_organization" {
  description = "Registration is limited to users included in this list, or users that are members of organizations included in this list."
}

variable "env_drone_webhook_list" {
  description = "String literal value provides a comma-separated list of webhook endpoints"
}

variable "env_drone_logs_debug" {
  description = "String literal for verboser output from logs "
}

variable "env_drone_repo_filter" {
}

variable "env_drone_agents_enabled" {
  default     = "true"
  description = "supported values are [true] one must set explicit since 1-0-0-rc-6 "
}

variable "env_drone_http_ssl_redirect" {
  default     = "true"
  description = "If is set to true, then only allow HTTPS requests."
}

variable "env_drone_auto_cert" {
  default     = "true"
  description = "auto cert drone supported [true]"
}

variable "env_drone_server_proto" {
  default     = "https"
  description = "server protocol"
}

variable "drone_auto_cert_port" {
  default     = 80
  description = "port used during auto cert"
}

variable "vpc_id" {
  description = "Id for vpc"
}

variable "cluster_id" {
  description = "Identifier of the cluster"
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "agent_log_group_arn" {
  description = "Log Group for Agent"
}

variable "service_discovery_private_namespace" {
  default     = "-tool.local"
  description = "private dns namepace"
}

variable "rpc_secret" {
  description = "RPC secret"
}

variable "cluster_instance_security_group_id" {
  description = "Security group of cluster instances"
}

variable "build_agent_port" {
  description = "port for build agents"
}

variable "ip_access_whitelist" {
  description = "White-listed cidr IP to access user interface. Allow from [Github Hook IP](https://api.github.com/meta)   "
  default     = ["0.0.0.0/0"]
}

variable "fqdn" {
  description = "Fully qualified domain name of ci"
}