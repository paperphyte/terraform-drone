locals {
  sub_domain  = var.ci_sub_domain
  root_domain = var.root_domain
}

resource "aws_vpc" "ci" {
  cidr_block           = "172.35.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_subnet" "ci_subnet_a" {
  vpc_id                  = aws_vpc.ci.id
  cidr_block              = "172.35.16.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_subnet" "ci_subnet_c" {
  vpc_id                  = aws_vpc.ci.id
  cidr_block              = "172.35.32.0/20"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}c"

  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_internet_gateway" "ci" {
  vpc_id = aws_vpc.ci.id

  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_route_table" "ci" {
  vpc_id = aws_vpc.ci.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ci.id
  }

  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.ci_subnet_a.id
  route_table_id = aws_route_table.ci.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.ci_subnet_c.id
  route_table_id = aws_route_table.ci.id
}

