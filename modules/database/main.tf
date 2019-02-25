locals {
  sub_domain                      = "${var.ci_sub_domain}"
  root_domain                     = "${var.root_domain}"
  vpc_id                          = "${var.vpc_id}"
  subnet_id_1                     = "${var.subnet_id_1}"
  subnet_id_2                     = "${var.subnet_id_2}"
  ci_server_app_security_group_id = "${var.ci_server_app_security_group_id}"
}

resource "aws_db_subnet_group" "ci_db" {
  name       = "ci_db_subnet_group"
  subnet_ids = ["${local.subnet_id_1}", "${local.subnet_id_2}"]

  tags = "${map("Name", "${local.sub_domain}.${local.root_domain}")}"
}

resource "aws_security_group" "ci_db" {
  name        = "ci-db-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${local.vpc_id}"
  tags        = "${map("Name", "${local.sub_domain}.${local.root_domain}")}"

  ingress {
    from_port = "${lookup(var.db_engine_port, var.db_engine)}"
    to_port   = "${lookup(var.db_engine_port, var.db_engine)}"
    protocol  = "TCP"

    security_groups = [
      "${local.ci_server_app_security_group_id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_string" "db_password" {
  special = false
  length  = 20
}

resource "aws_db_instance" "ci_db" {
  depends_on                = ["aws_security_group.ci_db"]
  identifier                = "${var.db_identifier}"
  allocated_storage         = "${var.db_storage}"
  engine                    = "${var.db_engine}"
  engine_version            = "${lookup(var.db_engine_version, var.db_engine)}"
  instance_class            = "${var.db_instance_class}"
  name                      = "${var.db_name}"
  username                  = "${var.db_username}"
  password                  = "${random_string.db_password.result}"
  vpc_security_group_ids    = ["${aws_security_group.ci_db.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.ci_db.id}"
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.sub_domain}-${md5(timestamp())}"
  deletion_protection       = false
  copy_tags_to_snapshot     = true
  tags                      = "${map("Name", "${local.sub_domain}.${local.root_domain}")}"
}
