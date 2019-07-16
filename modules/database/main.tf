resource "aws_db_subnet_group" "ci_db" {
  name       = "ci_db_subnet_group"
  subnet_ids = var.private_subnets

  tags = {
    Name = var.fqdn
  }
}


resource "aws_security_group" "ci_db" {
  name        = "ci-db-sg"
  description = "Allow all inbound traffic"
  vpc_id      = var.vpc_id
  tags = {
    Name = var.fqdn
  }

  ingress {
    from_port = var.db_engine_port[var.db_engine]
    to_port   = var.db_engine_port[var.db_engine]
    protocol  = "TCP"
    security_groups = [
      var.ci_server_app_security_group_id,
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
  depends_on                = [aws_security_group.ci_db]
  identifier                = var.db_identifier
  allocated_storage         = var.db_storage
  engine                    = var.db_engine
  engine_version            = var.db_engine_version[var.db_engine]
  instance_class            = var.db_instance_class
  name                      = var.db_name
  username                  = var.db_username
  password                  = random_string.db_password.result
  vpc_security_group_ids    = [aws_security_group.ci_db.id]
  db_subnet_group_name      = aws_db_subnet_group.ci_db.id
  skip_final_snapshot       = false
  final_snapshot_identifier = md5(var.fqdn)
  deletion_protection       = false
  copy_tags_to_snapshot     = true
  tags = {
    Name = var.fqdn
  }
}
