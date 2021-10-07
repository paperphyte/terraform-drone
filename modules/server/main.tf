locals {
  container_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/"
}
# ----------------------------------------
# Drone Server RDS Database
# ----------------------------------------

resource "aws_security_group" "db" {
  description = "Restrict access to database"
  vpc_id      = lookup(var.network, "vpc_id", null)
  name        = "drone-db-sg"
}

resource "aws_security_group_rule" "sb_default_egress" {
  type              = "egress"
  description       = "Outgoing db traffic rule"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
}

module "db" {
  source                     = "terraform-aws-modules/rds/aws"
  identifier                 = lookup(var.db, "name", null)
  version                    = "3.4.0"
  engine                     = "postgres"
  engine_version             = "13.4"
  auto_minor_version_upgrade = true
  delete_automated_backups   = false
  instance_class             = lookup(var.db, "instance_class", null)
  allocated_storage          = 20
  storage_encrypted          = false

  username = data.aws_ssm_parameter.db_user_name.value
  password = data.aws_ssm_parameter.db_password.value
  port     = lookup(var.db, "port", null)

  vpc_security_group_ids = [aws_security_group.db.id]
  subnet_ids             = lookup(var.network, "vpc_private_subnets", null)

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 30

  family                    = "postgres13"
  major_engine_version      = "13"
  final_snapshot_identifier = "drone-snapshot"
  deletion_protection       = true
}

resource "aws_security_group_rule" "db_self" {
  security_group_id = aws_security_group.db.id
  type              = "ingress"
  description       = "Incoming db traffic rule"
  protocol          = "tcp"
  from_port         = lookup(var.db, "port", null)
  to_port           = lookup(var.db, "port", null)
  self              = true
}

resource "aws_security_group_rule" "db_drone_task" {
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  description              = "Incoming db traffic rule"
  protocol                 = "tcp"
  from_port                = lookup(var.db, "port", null)
  to_port                  = lookup(var.db, "port", null)
  source_security_group_id = module.drone_server_task.service_sg_id
}

# ----------------------------------------
# Drone Server LB
# ----------------------------------------

module "drone_lb" {
  source             = "./modules/lb"
  vpc_id             = lookup(var.network, "vpc_id", null)
  vpc_public_subnets = lookup(var.network, "vpc_public_subnets", null)
  dns_root_name      = lookup(var.network, "dns_root_name", null)
  dns_hostname       = "drone"
  target_port        = 80
}

resource "aws_security_group_rule" "ssl_ingress" {
  type              = "ingress"
  description       = "Incoming"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = lookup(var.network, "allow_cidr_range", ["0.0.0.0/0"])
  security_group_id = module.drone_lb.lb_sg_id
}

# ----------------------------------------
# Drone Server Bucket
# ----------------------------------------

resource "aws_s3_bucket" "drone_build_log_storage" {
  provider = aws.eu_west
  bucket   = "drone-large-build-logs"
  acl      = "private"
  tags     = local.common_tags

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

# ----------------------------------------
# Drone Server Service
# ----------------------------------------

resource "random_string" "server_secret" {
  length  = 32
  special = false
}

module "drone_server_task" {
  source                        = "../task"
  vpc_id                        = lookup(var.network, "vpc_id", null)
  vpc_private_subnets           = lookup(var.network, "private_subnets", null)
  lb_target_group_id            = module.drone_lb.lb_target_group_id
  task_name                     = "drone-server"
  task_image                    = "drone/drone"
  task_image_version            = lookup(var.server_versions, "server", null)
  task_container_log_group_name = var.log_group_id
  container_registry            = local.container_registry
  task_bind_port                = 80
  load_balancer = [{
    target_group_arn = module.drone_lb.lb_target_group_id
    container_name   = "drone-server"
    container_port   = 80
  }]

  task_secret_vars = [
    {
      name      = "DRONE_GITHUB_CLIENT_ID"
      valueFrom = data.aws_ssm_parameter.github_client_id.arn
    },
    {
      name      = "DRONE_GITHUB_CLIENT_SECRET"
      valueFrom = data.aws_ssm_parameter.github_client_id.arn
    },
    {
      "name" : "DRONE_DATABASE_DATASOURCE",
      "valueFrom" : "postgres://${data.aws_ssm_parameter.db_user_name.value}:${data.aws_ssm_parameter.db_password.value}@${module.db.db_instance_address}:${lookup(var.db, "port", null)}/postgres?sslmode=disable"

    },
    {
      "name" : "DRONE_SERVER_SECRET",
      "valueFrom" : random_string.server_secret.result
    }
  ]
  task_environment_vars = [
    {
      "name" : "DRONE_LOGS_TRACE",
      "value" : "${var.drone_debug}"
    },
    {
      "name" : "DRONE_LOGS_DEBUG",
      "value" : "${var.drone_debug}"
    },
    {
      name  = "DRONE_DATABASE_DRIVER"
      value = "postgres"
    },
    {
      name  = "DRONE_REPOSITORY_FILTER"
      value = var.drone_user_filter
    },
    {
      name  = "DRONE_RPC_SERVER"
      value = "https://${modules.lb.fqdn}"
    },
    {
      name  = "DRONE_SERVER_PROTO"
      value = "https"
    },
    {
      name  = "DRONE_SERVER_HOST"
      value = modules.lb.fqdn
    },
    {
      name  = "DRONE_TLS_AUTOCERT"
      value = "false"
    },
    {
      name  = "DRONE_USER_CREATE"
      value = "username:${var.drone_admin},machine:false,admin:true"
    },
    {
      name  = "DRONE_USER_FILTER"
      value = var.drone_user_filter
    },
    {
      name  = "DRONE_GImodules.lb.fqdnTHUB_SERVER"
      value = "https://github.com"
    },
    {
      name  = "DRONE_AGENTS_ENABLED"
      value = "true"
    },
    {
      name  = "DRONE_HTTP_SSL_REDIRECT"
      value = "false"
    },
    {
      name  = "DRONE_S3_BUCKET"
      value = aws_s3_bucket.drone_build_log_storage.name
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    },
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    },
    {
      "name" : "DRONE_CLEANUP_INTERVAL",
      "value" : "24h"
    },
    {
      "name" : "DRONE_CLEANUP_DEADLINE_RUNNING",
      "value" : "6h"
    },
    {
      "name" : "DRONE_CLEANUP_DEADLINE_PENDING",
      "value" : "72h"
    }
  ]
}

# ----------------------------------------
# RDS EC2 SSM Instance Helper
# ----------------------------------------

resource "aws_iam_role" "instance_helper" {
  name = "drone-instance-helper"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_helper" {
  role       = aws_iam_role.instance_helper.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance_helper" {
  name = "drone-instance-helper"
  role = aws_iam_role.instance_helper.name
}

resource "aws_instance" "instance_helper" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.nano"
  iam_instance_profile   = aws_iam_instance_profile.instance_helper.name
  vpc_security_group_ids = [aws_security_group.db.id]
  subnet_id              = element(var.vpc_private_subnets, 1)
  user_data = templatefile(
    "${path.module}/templates/helper-userdata.sh.tpl",
    {
      PGNAME     = lookup(var.db, "name", null)
      PGHOST     = module.db.db_instance_address
      PGUSER     = data.aws_ssm_parameter.db_user_name.value
      PGPASSWORD = data.aws_ssm_parameter.db_password.value
      PGDATABASE = "postgres"
      PGSSLMODE  = "disable"
    }
  )
  tags = {
    Name = "drone-instance-helper"
  }
}
