variable "max_instances_count" {
  description = "Max container instances running"
}

variable "min_instances_count" {
  description = "Min container instances running"
}

variable "ecs_optimized_ami" {
  type        = map(string)
  description = "map of optimized amis"
}

variable "aws_region" {
  description = "AWS region where ci is deployed"
}

variable "instance_type" {
  description = "EC2 Instance Type."
}

variable "keypair_name" {
  description = "Name of A pre-existing keypair"
}

variable "server_log_group_arn" {
  description = "Log group for server"
}

variable "agent_log_group_arn" {
  description = "Log Group for Agent"
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

variable "cluster_name" {
  default     = "ci_server"
  description = "The name of the cluster"
}

variable "ip_access_whitelist" {
  description = "White-list of who can access the ci server"
  type        = list(string)
}

variable "ec2_volume_size" {
  default     = 100
  description = "Size of ec2 disk in GB"
}

