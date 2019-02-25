locals {
  subnet_id_1  = "${aws_subnet.ci_subnet_a.id}"
  subnet_id_2  = "${aws_subnet.ci_subnet_c.id}"
  keypair_name = "${aws_key_pair.ci_tool.key_name}"
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
  ci_server_app_security_group_id = "${aws_security_group.ci_server_app.id}"
}

module "ci_ecs_cluster" {
  source               = "./modules/cluster"
  server_log_group_arn = "${aws_cloudwatch_log_group.drone_agent.arn}"
  agent_log_group_arn  = "${aws_cloudwatch_log_group.drone_server.arn}"
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
  source                   = "./modules/lb"
  ci_sub_domain            = "${var.ci_sub_domain}"
  root_domain              = "${var.root_domain}"
  vpc_id                   = "${aws_vpc.ci.id}"
  subnet_id_1              = "${local.subnet_id_1}"
  subnet_id_2              = "${local.subnet_id_2}"
  root_domain_zone_id      = "${var.root_domain_zone_id}"
  target_port              = "${var.drone_server_port}"
  target_security_group_id = "${aws_security_group.ci_server_web.id}"
}
