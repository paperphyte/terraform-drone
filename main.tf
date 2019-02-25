resource "random_string" "drone_rpc_secret" {
  length  = 32
  special = false
}

locals {
  subnet_id_1  = "${aws_subnet.ci_subnet_a.id}"
  subnet_id_2  = "${aws_subnet.ci_subnet_c.id}"
  keypair_name = "${aws_key_pair.ci_tool.key_name}"
  rpc_secret   = "${random_string.drone_rpc_secret.id}"
}

resource "aws_key_pair" "ci_tool" {
  key_name   = "ci-tools"
  public_key = "${var.ci_tool_pubkey}"
}

resource "aws_vpc" "ci" {
  cidr_block           = "172.35.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_subnet" "ci_subnet_a" {
  vpc_id                  = "${aws_vpc.ci.id}"
  cidr_block              = "172.35.16.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_subnet" "ci_subnet_c" {
  vpc_id                  = "${aws_vpc.ci.id}"
  cidr_block              = "172.35.32.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}c"

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_internet_gateway" "ci" {
  vpc_id = "${aws_vpc.ci.id}"

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_route_table" "ci" {
  vpc_id = "${aws_vpc.ci.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ci.id}"
  }

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.ci_subnet_a.id}"
  route_table_id = "${aws_route_table.ci.id}"
}

resource "aws_route_table_association" "c" {
  subnet_id      = "${aws_subnet.ci_subnet_c.id}"
  route_table_id = "${aws_route_table.ci.id}"
}

module "ci_db" {
  source                          = "./modules/database"
  db_identifier                   = "${var.ci_db_identifier}"
  db_storage                      = "${var.ci_db_storage}"
  db_instance_class               = "${var.ci_db_instance_class}"
  db_name                         = "${var.ci_db_name}"
  db_username                     = "${var.ci_db_username}"
  ci_sub_domain                   = "${var.ci_sub_domain}"
  root_domain                     = "${var.root_domain}"
  vpc_id                          = "${aws_vpc.ci.id}"
  subnet_id_1                     = "${local.subnet_id_1}"
  subnet_id_2                     = "${local.subnet_id_2}"
  ci_server_app_security_group_id = "${module.ci_server.ci_server_security_group_id}"
}

module "ci_ecs_cluster" {
  source               = "./modules/cluster"
  server_log_group_arn = "${module.build_agent.drone_agent_log_group_arn}"
  agent_log_group_arn  = "${module.ci_server.drone_server_log_group_arn}"
  ci_sub_domain        = "${var.ci_sub_domain}"
  root_domain          = "${var.root_domain}"
  vpc_id               = "${aws_vpc.ci.id}"
  subnet_id_1          = "${local.subnet_id_1}"
  subnet_id_2          = "${local.subnet_id_2}"
  min_instances_count  = "${var.ci_ecs_min_instances_count}"
  max_instances_count  = "${var.ci_ecs_max_instances_count}"
  ecs_optimized_ami    = "${var.ecs_optimized_ami}"
  aws_region           = "${var.aws_region}"
  instance_type        = "${var.ci_ec2_instance_type}"
  ecs_optimized_ami    = "${var.ecs_optimized_ami}"
  keypair_name         = "${local.keypair_name}"
}

module "load_balancer" {
  source              = "./modules/lb"
  ci_sub_domain       = "${var.ci_sub_domain}"
  root_domain         = "${var.root_domain}"
  vpc_id              = "${aws_vpc.ci.id}"
  subnet_id_1         = "${local.subnet_id_1}"
  subnet_id_2         = "${local.subnet_id_2}"
  root_domain_zone_id = "${var.root_domain_zone_id}"
  target_port         = "${var.drone_server_port}"
  ip_access_whitelist = "${var.alb_ingres_cidr_whitelist}"
}

module "build_agent" {
  source              = "./modules/drone-agent"
  ci_sub_domain       = "${var.ci_sub_domain}"
  root_domain         = "${var.root_domain}"
  rpc_server          = "${module.ci_server.rpc_server_url}"
  rpc_secret          = "${local.rpc_secret}"
  aws_region          = "${var.aws_region}"
  app_version         = "${var.drone_version}"
  app_debug           = "${var.env_drone_logs_debug}"
  container_cpu       = "${var.ecs_container_cpu}"
  container_memory    = "${var.ecs_container_memory}"
  cluster_id          = "${module.ci_ecs_cluster.id}"
  cluster_name        = "${module.ci_ecs_cluster.name}"
  min_container_count = "${var.drone_agent_min_count}"
  max_container_count = "${var.drone_agent_max_count}"
}

module "ci_server" {
  source                             = "./modules/drone-server"
  db_host_name                       = "${module.ci_db.address}"
  db_user                            = "${module.ci_db.user}"
  db_password                        = "${module.ci_db.root_password}"
  db_engine                          = "${module.ci_db.engine}"
  db_port                            = "${module.ci_db.port}"
  rpc_secret                         = "${local.rpc_secret}"
  ci_sub_domain                      = "${var.ci_sub_domain}"
  root_domain                        = "${var.root_domain}"
  aws_region                         = "${var.aws_region}"
  app_version                        = "${var.drone_version}"
  app_debug                          = "${var.env_drone_logs_debug}"
  app_port                           = "${var.drone_server_port}"
  agent_log_group_arn                = "${module.build_agent.drone_agent_log_group_arn}"
  cluster_name                       = "${module.ci_ecs_cluster.name}"
  cluster_id                         = "${module.ci_ecs_cluster.id}"
  target_group_arn                   = "${module.load_balancer.target_group_arn}"
  subnet_id_1                        = "${local.subnet_id_1}"
  subnet_id_2                        = "${local.subnet_id_2}"
  env_github_client                  = "${var.env_github_client}"
  env_github_secret                  = "${var.env_github_secret}"
  env_drone_admin                    = "${var.env_drone_admin}"
  env_drone_github_organization      = "${var.env_drone_github_organization}"
  env_drone_webhook_list             = "${var.env_drone_webhook_list}"
  env_drone_logs_debug               = "${var.env_drone_logs_debug}"
  env_drone_repo_filter              = "${var.env_drone_repo_filter}"
  fargate_task_cpu                   = "${var.fargate_task_cpu}"
  fargate_task_memory                = "${var.fargate_task_memory}"
  vpc_id                             = "${aws_vpc.ci.id}"
  cluster_instance_security_group_id = "${module.ci_ecs_cluster.cluster_instance_security_group_id}"
  load_balancer_security_group_id    = "${module.load_balancer.load_balancer_security_group_id}"
  build_agent_port                   = "${var.drone_agent_port}"
}
