variable "root_domain" {
  description = "Pre-existing Route53 Hosted Zone domain"
}

variable "ci_sub_domain" {
  description = "Sub part of domain for ci"
}

variable "db_host_name" {}
variable "db_user" {}
variable "db_password" {}
variable "db_engine" {}
variable "db_port" {}

variable "subnet_id_1" {}
variable "subnet_id_2" {}

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

variable "env_drone_repo_filter" {}

variable "env_drone_agents_enabled" {
  default     = "true"
  description = "supported values are [true] one must set explicit since 1-0-0-rc-6 "
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
  default     = "ci-tool.local"
  description = "private dns namepace"
}

variable "target_group_arn" {
  description = "Target group resource arn"
}

variable "rpc_secret" {
  description = "RPC secret"
}

variable "cluster_instance_security_group_id" {
  description = "Security group of cluster instances"
}

variable "load_balancer_security_group_id" {
  description = "Security group of load balancer"
}

variable "build_agent_port" {
  description = "port for build agents"
}
