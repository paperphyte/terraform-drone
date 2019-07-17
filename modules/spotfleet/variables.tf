variable "ec2_volume_size" {
  default     = 100
  description = "Size of ec2 disk in GB"
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
variable "private_subnets" {
  description = "private subnet ids"
  type        = list
}

variable "public_subnets" {
  description = "public subnet ids"
  type        = list
}

variable "keypair_name" {
  description = "Name of A pre-existing keypair"
}

variable "instance_type" {
  description = "EC2 Instance Type."
}

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "cluster_instance_user_data" {
  description = "User data for launching new spot instance"
}

variable "fqdn" {
  description = "Fully qualified domain name of ci"
}
