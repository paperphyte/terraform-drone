locals {
  keypair_name                       = "${aws_key_pair.ci_tool.key_name}"
  rpc_secret                         = "${random_string.drone_rpc_secret.id}"
  subnet_id_1                        = "${module.network.subnet_id_1}"
  subnet_id_2                        = "${module.network.subnet_id_2}"
  vpc_id                             = "${module.network.vpc_id}"
  ci_server_app_security_group_id    = "${module.ci_server.ci_server_security_group_id}"
  cluster_instance_security_group_id = "${module.ci_ecs_cluster.instance_security_group_id}"
  cluster_ami_image_id               = "${module.ci_ecs_cluster.ami_image_id}"
  cluster_iam_instance_profile       = "${module.ci_ecs_cluster.iam_instance_profile}"
  load_balancer_security_group_id    = "${module.load_balancer.load_balancer_security_group_id}"
  server_log_group_arn               = "${module.ci_server.drone_server_log_group_arn}"
  agent_log_group_arn                = "${module.build_agent.drone_agent_log_group_arn}"
  rpc_server_url                     = "${module.ci_server.rpc_server_url}"
  cluster_id                         = "${module.ci_ecs_cluster.id}"
  cluster_name                       = "${module.ci_ecs_cluster.name}"
  target_group_arn                   = "${module.load_balancer.target_group_arn}"
  db_host_name                       = "${module.ci_db.address}"
  db_user                            = "${module.ci_db.user}"
  db_password                        = "${module.ci_db.root_password}"
  db_engine                          = "${module.ci_db.engine}"
  db_port                            = "${module.ci_db.port}"
  cluster_instance_user_data         = "${module.ci_ecs_cluster.instance_user_data}"
}

resource "random_string" "drone_rpc_secret" {
  length  = 32
  special = false
}

resource "aws_key_pair" "ci_tool" {
  key_name   = "ci-tools"
  public_key = "${var.keypair_public_key}"
}

module "network" {
  source        = "./modules/network"
  aws_region    = "${var.aws_region}"
  ci_sub_domain = "${var.ci_sub_domain}"
  root_domain   = "${var.root_domain}"
}

module "ci_db" {
  source                          = "./modules/database"
  vpc_id                          = "${local.vpc_id}"
  subnet_id_1                     = "${local.subnet_id_1}"
  subnet_id_2                     = "${local.subnet_id_2}"
  ci_server_app_security_group_id = "${local.ci_server_app_security_group_id}"
  db_identifier                   = "${var.db_identifier}"
  db_storage                      = "${var.db_storage_size}"
  db_instance_class               = "${var.db_instance_type}"
  db_name                         = "${var.db_name}"
  db_username                     = "${var.db_user}"
  ci_sub_domain                   = "${var.ci_sub_domain}"
  root_domain                     = "${var.root_domain}"
}

module "ci_ecs_cluster" {
  source               = "./modules/cluster"
  server_log_group_arn = "${local.server_log_group_arn}"
  agent_log_group_arn  = "${local.agent_log_group_arn}"
  vpc_id               = "${local.vpc_id}"
  subnet_id_1          = "${local.subnet_id_1}"
  subnet_id_2          = "${local.subnet_id_2}"
  keypair_name         = "${local.keypair_name}"
  ci_sub_domain        = "${var.ci_sub_domain}"
  root_domain          = "${var.root_domain}"
  min_instances_count  = "${var.ecs_min_instances_count}"
  max_instances_count  = "${var.ecs_max_instances_count}"
  ecs_optimized_ami    = "${var.ecs_optimized_ami}"
  aws_region           = "${var.aws_region}"
  instance_type        = "${var.ecs_cluster_instance_type}"
  ecs_optimized_ami    = "${var.ecs_optimized_ami}"
  ip_access_whitelist  = "${var.ip_access_whitelist}"
}

module "ci_ecs_cluster_spotfleet" {
  source                             = "./modules/spotfleet"
  cluster_spot_instance_enabled      = "${var.cluster_spot_instance_enabled}"
  server_log_group_arn               = "${local.server_log_group_arn}"
  agent_log_group_arn                = "${local.agent_log_group_arn}"
  subnet_id_1                        = "${local.subnet_id_1}"
  subnet_id_2                        = "${local.subnet_id_2}"
  keypair_name                       = "${local.keypair_name}"
  cluster_instance_security_group_id = "${local.cluster_instance_security_group_id}"
  cluster_ami_image_id               = "${local.cluster_ami_image_id}"
  cluster_name                       = "${local.cluster_name}"
  cluster_iam_instance_profile       = "${local.cluster_iam_instance_profile}"
  cluster_instance_user_data         = "${local.cluster_instance_user_data}"
  ci_sub_domain                      = "${var.ci_sub_domain}"
  root_domain                        = "${var.root_domain}"
  instance_type                      = "${var.ecs_cluster_instance_type}"
  ec2_volume_size                    = "${var.ec2_volume_size}"

  target_capacity     = "${var.spot_fleet_target_capacity}"
  bid_price           = "${var.spot_fleet_bid_price}"
  allocation_strategy = "${var.spot_fleet_allocation_strategy}"
  valid_until         = "${var.spot_fleet_valid_until}"
}

module "load_balancer" {
  source              = "./modules/lb"
  vpc_id              = "${local.vpc_id}"
  subnet_id_1         = "${local.subnet_id_1}"
  subnet_id_2         = "${local.subnet_id_2}"
  ci_sub_domain       = "${var.ci_sub_domain}"
  root_domain         = "${var.root_domain}"
  root_domain_zone_id = "${var.root_domain_zone_id}"
  target_port         = "${var.drone_server_port}"
  ip_access_whitelist = "${var.ip_access_whitelist}"
}

module "build_agent" {
  source              = "./modules/drone-agent"
  rpc_server          = "${local.rpc_server_url}"
  rpc_secret          = "${local.rpc_secret}"
  cluster_id          = "${local.cluster_id}"
  cluster_name        = "${local.cluster_name}"
  ci_sub_domain       = "${var.ci_sub_domain}"
  root_domain         = "${var.root_domain}"
  aws_region          = "${var.aws_region}"
  app_version         = "${var.drone_version}"
  app_debug           = "${var.env_drone_logs_debug}"
  container_cpu       = "${var.ecs_container_cpu}"
  container_memory    = "${var.ecs_container_memory}"
  min_container_count = "${var.drone_agent_min_count}"
  max_container_count = "${var.drone_agent_max_count}"
}

module "ci_server" {
  source                             = "./modules/drone-server"
  db_host_name                       = "${local.db_host_name}"
  db_user                            = "${local.db_user}"
  db_password                        = "${local.db_password}"
  db_engine                          = "${local.db_engine}"
  db_port                            = "${local.db_port}"
  rpc_secret                         = "${local.rpc_secret}"
  agent_log_group_arn                = "${local.agent_log_group_arn}"
  cluster_name                       = "${local.cluster_name}"
  cluster_id                         = "${local.cluster_id}"
  target_group_arn                   = "${local.target_group_arn}"
  subnet_id_1                        = "${local.subnet_id_1}"
  subnet_id_2                        = "${local.subnet_id_2}"
  vpc_id                             = "${local.vpc_id}"
  cluster_instance_security_group_id = "${local.cluster_instance_security_group_id}"
  load_balancer_security_group_id    = "${local.load_balancer_security_group_id}"
  env_github_client                  = "${var.env_github_client}"
  env_github_secret                  = "${var.env_github_secret}"
  env_drone_admin                    = "${var.env_drone_admin}"
  env_drone_github_organization      = "${var.env_drone_github_organization}"
  env_drone_webhook_list             = "${var.env_drone_webhook_list}"
  env_drone_logs_debug               = "${var.env_drone_logs_debug}"
  env_drone_repo_filter              = "${var.env_drone_repo_filter}"
  fargate_task_cpu                   = "${var.fargate_task_cpu}"
  fargate_task_memory                = "${var.fargate_task_memory}"
  ci_sub_domain                      = "${var.ci_sub_domain}"
  root_domain                        = "${var.root_domain}"
  aws_region                         = "${var.aws_region}"
  app_version                        = "${var.drone_version}"
  app_debug                          = "${var.env_drone_logs_debug}"
  app_port                           = "${var.drone_server_port}"
  build_agent_port                   = "${var.drone_agent_port}"
}
