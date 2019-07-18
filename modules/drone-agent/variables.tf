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

variable "fqdn" {
  description = "Fully qualified domain name of ci"
}

variable "drone_secrets_shared_secret" {
  description = "Shared secret key used to authenticate incoming requests, and encrypt the response body."
}

variable "drone_secrets_url" {
  description = "Endpoint for accessing the secrets plugin"
}

