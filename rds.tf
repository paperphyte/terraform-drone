resource "aws_db_subnet_group" "ci_db" {
  name       = "ci_db_subnet_group"
  subnet_ids = ["${aws_subnet.ci_subnet_a.id}", "${aws_subnet.ci_subnet_c.id}"]

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_security_group" "ci_db" {
  name        = "ci-db-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.ci.id}"
  tags        = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"

  ingress {
    from_port = "${lookup(var.ci_db_engine_port, var.ci_db_engine)}"
    to_port   = "${lookup(var.ci_db_engine_port, var.ci_db_engine)}"
    protocol  = "TCP"

    security_groups = [
      "${aws_security_group.ci_server_app.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_string" "ci_db_password" {
  special = false
  length  = 20
}

resource "aws_db_instance" "ci_db" {
  depends_on                = ["aws_security_group.ci_db"]
  identifier                = "${var.ci_db_identifier}"
  allocated_storage         = "${var.ci_db_storage}"
  engine                    = "${var.ci_db_engine}"
  engine_version            = "${lookup(var.ci_db_engine_version, var.ci_db_engine)}"
  instance_class            = "${var.ci_db_instance_class}"
  name                      = "${var.ci_db_name}"
  username                  = "${var.ci_db_username}"
  password                  = "${random_string.ci_db_password.result}"
  vpc_security_group_ids    = ["${aws_security_group.ci_db.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.ci_db.id}"
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.ci_sub_domain}-${md5(timestamp())}"
  deletion_protection       = false
  copy_tags_to_snapshot     = true
  tags                      = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}
