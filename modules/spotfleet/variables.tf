variable "ec2_volume_size" {
  default     = 100
  description = "Size of ec2 disk in GB"
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

variable "cluster_ami_image_id" {
  description = "Image ID for ec2 cluster instances"
}

variable "cluster_iam_instance_profile" {
  description = "Size of ec2 disk in GB"
}

variable "cluster_instance_security_group_id" {
  description = "Security group of cluster instances"
}

variable "server_log_group_arn" {
  description = "Log group for server"
}

variable "agent_log_group_arn" {
  description = "Log Group for Agent"
}

variable "subnet_id_1" {
  description = "id for subnet"
}

variable "subnet_id_2" {
  description = "id for subnet"
}

variable "keypair_name" {
  description = "Name of A pre-existing keypair"
}

variable "root_domain" {
  description = "Pre-existing Route53 Hosted Zone domain"
}

variable "ci_sub_domain" {
  description = "Sub part of domain for ci"
}

variable "instance_type" {
  description = "EC2 Instance Type."
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "cluster_spot_instance_enabled" {
  description = "Seeding using spot instances enabled"
}

variable "cluster_instance_user_data" {
  description = "User data for launching new spot instance"
}

