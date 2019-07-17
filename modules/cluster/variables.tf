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

variable "node_scaling_cooldown" {
  description = "Node fleet scaling cooldown"
  default     = 300
}

variable "min_node_fleet_requests_count" {
  description = "Min slaves"
  default = 1
}

variable "max_node_fleet_requests_count" {
  description = "Max slaves"
  default = 4
}

variable "node_instance_type" {
  type        = map
  description = "Node instance type"
  default = {
    t3Medium = {
      price = 0.02
      name  = "t3.medium"
    }
    m5Large = {
      price = 0.03
      name  = "m5.large"
    }
  }
}

variable "target_capacity" {
  description = "Target number of spot instances to seed the cluster with"
}

variable "bid_price" {
  description = "Bid price for cluster resources"
}

variable "allocation_strategy" {
  description = "Strategy for seeding instances cross pools. Config only support one pool for now."
}

variable "valid_until" {
  description = "Amount of time a spot fleet bid should stay active"
}