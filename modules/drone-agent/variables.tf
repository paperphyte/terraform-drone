variable "app_version" {
  description = "Current Drone Agent Version"
}

variable "app_debug" {
  description = "Verbose logging of agent communication"
}

variable "aws_region" {
  description = "The AWS Region"
}

variable "container_memory" {
  description = "Requested container memory"
}

variable "container_cpu" {
  description = "Requested container cpu"
}

variable "rpc_secret" {
  description = "Secret for RPC communication"
}

variable "rpc_server" {
  description = "Server the agent communicates with"
}

variable "cluster_id" {
  description = "Identifier of the cluster"
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "min_container_count" {
  description = "Minimum number of agents"
}

variable "max_container_count" {
  description = "Maximum number of agents"
}

variable "root_domain" {
  description = "Pre-existing Route53 Hosted Zone domain"
}

variable "ci_sub_domain" {
  description = "Sub part of domain for ci"
}
