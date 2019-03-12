variable "db_identifier" {
  default     = "ci-rds"
  description = "Identifier for RDS instance"
}

variable "db_storage_size" {
  default     = "10"
  description = "Storage size of RDS instance in GB"
}

variable "db_instance_type" {
  default     = "db.t3.micro"
  description = "RDS instance types "
}

variable "db_name" {
  default     = "ci_db"
  description = "Database Name"
}

variable "db_user" {
  default     = "ci_user"
  description = "Database user name"
}

variable "aws_region" {
  description = "AWS region where the CI/CD gets deployed"
  default     = "eu-west-1"
}

variable "root_domain_zone_id" {
  description = "Pre-existing Route53 Hosted Zone ID"
}

variable "root_domain" {
  default     = "example.com"
  description = "Pre-existing Route53 Hosted Zone domain"
}

variable "ci_sub_domain" {
  default     = "ci"
  description = "Sub-domain / hostname to access ci"
}

variable "ip_access_whitelist" {
  description = "White-listed cidr IP to access user interface. Allow from [Github Hook IP](https://api.github.com/meta)   "
  default     = ["0.0.0.0/0"]
}

variable "keypair_public_key" {
  description = "Pubkey of A pre-existing keypair"
}

variable "default_ttl" {
  default     = "300"
  description = "Default ttl for domain records"
}

variable "ecs_cluster_instance_type" {
  description = "EC2 Instance Type."
  default     = "t3.micro"
}

variable "ecs_min_instances_count" {
  description = "Min container instances running"
  default     = "1"
}

variable "ecs_max_instances_count" {
  description = "Max container instances running."
  default     = "1"
}

variable "ecs_optimized_ami" {
  type = "map"

  #
  # Launching an Amazon ECS Container Instance
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
  #
  default = {
    us-east-2      = "ami-0cca5d0eeadc8c3c4"
    us-east-1      = "ami-0a6a36557ea3b9859"
    us-west-2      = "ami-0d2f82a622136a696"
    us-west-1      = "ami-066a6b3ae13abc046"
    eu-west-3      = "ami-020cc3695affa4b6b"
    eu-west-2      = "ami-0e1065cc4f7231034"
    eu-west-1      = "ami-00921cd1ce43d567a"
    eu-central-1   = "ami-042ae7188819e7e9b"
    eu-north-1     = "ami-0a92075786c5779b9"
    ap-northeast-2 = "ami-0e0d82e1272b5ae8a"
    ap-northeast-1 = "ami-084cb340923dc7101"
    ap-southeast-2 = "ami-051b682e0d63cc816"
    ap-southeast-1 = "ami-0eb4239fe0f64fe58"
    ca-central-1   = "ami-0d9198a587e83919b"
    ap-south-1     = "ami-0d7805fed18723d71"
    sa-east-1      = "ami-0c4cd93b06ee26c34"
    us-gov-east-1  = "ami-04a689185b06da6db"
    us-gov-west-1  = "ami-7a5d361b"
  }
}

variable "ecs_container_cpu" {
  description = "Requested ecs container CPU"
  default     = "2000"
}

variable "ecs_container_memory" {
  description = "Requested ecs container memory"
  default     = "768"
}

variable "fargate_task_cpu" {
  default     = "256"
  description = " [Fargate task CPU and memory at the task level](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)"
}

variable "fargate_task_memory" {
  description = " [Fargate task CPU and memory at the task level](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html)"
  default     = "512"
}

variable "drone_server_port" {
  description = "Port of Drone Server"
  default     = 443
}

variable "drone_agent_port" {
  description = "Port of drone agent."
  default     = 443
}

variable "drone_agent_min_count" {
  description = "Min drone agens running."
  default     = "1"
}

variable "drone_agent_max_count" {
  description = "Max drone agents running."
  default     = "2"
}

variable "drone_version" {
  description = "Ci Drone version."
  default     = "1.0.0-rc.6"
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
  default     = "https://localhost?lis45"
}

variable "env_drone_logs_debug" {
  description = "String literal for verboser output from logs "
  default     = "false"
}

variable "env_drone_repo_filter" {
  description = "whitliest repositories"
}

variable "ec2_volume_size" {
  default     = "25"
  description = "Size of ec2 disk in GB"
}

variable "cluster_spot_instance_enabled" {
  default     = "1"
  description = "Seed Cluster with spot priced ec2 instances 0/1 true/false"
}

variable "spot_fleet_target_capacity" {
  default     = "1"
  description = "Target number of spot instances to seed the cluster with"
}

variable "spot_fleet_bid_price" {
  default     = "0.007"
  description = "Bid price for cluster resources"
}

variable "spot_fleet_allocation_strategy" {
  default     = "diversified"
  description = "Strategy for seeding instances cross pools. Config only support one pool for now."
}

variable "spot_fleet_valid_until" {
  description = "Amount of time a spot fleet bid should stay active"
  default     = "2022-02-22T02:02:02Z"
}

variable "update_dns_lambda_name" {
  description = "Function name for lambda used to update DNS of drone server"
  default     = "update_drone_ci_domain"
}

variable "load_balancer_enabled" {
  default     = "false"
  description = "Run the ci-server without loadbalancer"
}
