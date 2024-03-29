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

  name     = lookup(var.db, "name", null)
  username = data.aws_ssm_parameter.db_user_name.value
  password = data.aws_ssm_parameter.db_password.value
  port     = lookup(var.db, "port", null)

  vpc_security_group_ids = [aws_security_group.db.id]
  subnet_ids             = lookup(var.network, "vpc_private_subnets")

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
  source       = "../lb"
  network      = var.network
  dns_hostname = "drone"
  target_port  = 80
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
  bucket = "drone.${lookup(var.network, "dns_root_name")}-console-logs"

  acl = "private"

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
# Bitbeats Monorepo YAML Extension
# ----------------------------------------

resource "random_string" "yaml_secret" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "yaml_secret" {
  name      = "/drone/server/yaml_secret"
  type      = "String"
  value     = random_string.yaml_secret.result
  overwrite = true
}

module "drone_yaml_task" {
  source                             = "../task"
  service_name                       = "yaml-extension"
  vpc_id                             = lookup(var.network, "vpc_id", null)
  vpc_private_subnets                = lookup(var.network, "vpc_private_subnets", null)
  task_name                          = "yaml-extension"
  task_image                         = "bitsbeats/drone-tree-config"
  task_image_version                 = lookup(var.server_versions, "yaml", null)
  task_container_log_group_name      = var.log_group_id
  container_registry                 = local.container_registry
  service_discovery_dns_namespace_id = module.drone_lb.service_discovery_private_dns_namespace_id
  service_cluster_name               = lookup(var.network, "cluster_name", null)
  service_cluster_id                 = lookup(var.network, "cluster_id", null)
  task_bind_port                     = 3000

  task_secret_vars = [
    {
      name      = "PLUGIN_SECRET"
      valueFrom = aws_ssm_parameter.yaml_secret.arn
    },
    {
      name      = "GITHUB_TOKEN"
      valueFrom = data.aws_ssm_parameter.yaml_extension_github_token.arn
    }
  ]

  task_environment_vars = [
    {
      name  = "PLUGIN_DEBUG",
      value = "${var.drone_debug}"
    },
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    },
    {
      name  = "PLUGIN_CONSIDER_FILE"
      value = ".drone-consider"
    },
    {
      name  = "PLUGIN_CACHE_TTL"
      value = "30m"
    }
  ]
}

# ----------------------------------------
# Drone Server Service
# ----------------------------------------

resource "random_string" "server_secret" {
  length  = 32
  special = false
}

resource "random_string" "database_secret" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "data_source" {
  name  = "/drone/db/datasource"
  type  = "String"
  value = "postgres://${data.aws_ssm_parameter.db_user_name.value}:${data.aws_ssm_parameter.db_password.value}@${module.db.db_instance_address}:${lookup(var.db, "port", null)}/postgres?sslmode=disable"
}

resource "aws_ssm_parameter" "rpc_secret" {
  name      = "/drone/server/rpc_secret"
  type      = "String"
  value     = random_string.server_secret.result
  overwrite = true
}

resource "aws_ssm_parameter" "database_secret" {
  name      = "/drone/server/database_secret"
  type      = "String"
  value     = random_string.database_secret.result
  overwrite = true
}

module "drone_server_task" {
  source                             = "../task"
  service_name                       = "drone-server"
  vpc_id                             = lookup(var.network, "vpc_id", null)
  vpc_private_subnets                = lookup(var.network, "vpc_private_subnets", null)
  task_name                          = "drone-server"
  task_image                         = "drone/drone"
  task_image_version                 = lookup(var.server_versions, "server", null)
  task_container_log_group_name      = var.log_group_id
  container_registry                 = local.container_registry
  service_discovery_dns_namespace_id = module.drone_lb.service_discovery_private_dns_namespace_id
  service_cluster_name               = lookup(var.network, "cluster_name", null)
  service_cluster_id                 = lookup(var.network, "cluster_id", null)
  task_bind_port                     = 80
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
      valueFrom = data.aws_ssm_parameter.github_client_secret.arn
    },
    {
      name      = "DRONE_DATABASE_DATASOURCE"
      valueFrom = aws_ssm_parameter.data_source.arn
    },
    {
      name      = "DRONE_RPC_SECRET",
      valueFrom = aws_ssm_parameter.rpc_secret.arn
    },
    {
      name      = "DRONE_DATABASE_SECRET",
      valueFrom = aws_ssm_parameter.database_secret.arn
    },
    {
      name      = "DRONE_YAML_SECRET",
      valueFrom = aws_ssm_parameter.yaml_secret.arn
    }
  ]

  task_environment_vars = [
    {
      name  = "DRONE_YAML_ENDPOINT"
      value = "http://yaml-extension.drone.local:3000"
    },
    {
      name  = "DRONE_LOGS_TRACE"
      value = "${var.drone_debug}"
    },
    {
      name  = "DRONE_LOGS_DEBUG",
      value = "${var.drone_debug}"
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
      value = "https://${module.drone_lb.fqdn}"
    },
    {
      name  = "DRONE_SERVER_PROTO"
      value = "https"
    },
    {
      name  = "DRONE_SERVER_HOST"
      value = module.drone_lb.fqdn
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
      name  = "DRONE_GITHUB_SERVER"
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
      value = aws_s3_bucket.drone_build_log_storage.bucket
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
      name  = "DRONE_CLEANUP_INTERVAL",
      value = "24h"
    },
    {
      name  = "DRONE_CLEANUP_DEADLINE_RUNNING",
      value = "6h"
    },
    {
      name  = "DRONE_CLEANUP_DEADLINE_PENDING",
      value = "72h"
    }
  ]
}


resource "aws_security_group_rule" "lb_server_ingress_rule" {
  security_group_id        = module.drone_server_task.service_sg_id
  description              = "Allow LB to communicate the Fargate ECS service."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = module.drone_lb.lb_sg_id
}

resource "aws_security_group_rule" "server_yaml_ingress_rule" {
  security_group_id        = module.drone_yaml_task.service_sg_id
  description              = "Allow drone server connections to yaml extension."
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3000
  to_port                  = 3000
  source_security_group_id = module.drone_server_task.service_sg_id
}

resource "aws_iam_policy" "server_task_policy" {
  name = "server_task_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.drone_build_log_storage.bucket}*",
        "arn:aws:s3:::${aws_s3_bucket.drone_build_log_storage.bucket}*/"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "server_task_custom" {
  role       = module.drone_server_task.task_role_id
  policy_arn = aws_iam_policy.server_task_policy.arn
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
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.nano"
  iam_instance_profile   = aws_iam_instance_profile.instance_helper.name
  vpc_security_group_ids = [aws_security_group.db.id]
  subnet_id              = element(var.network["vpc_private_subnets"], 0)
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

# ----------------------------------------
# Amazon Secrets Manager
# ----------------------------------------

resource "random_string" "secret_secret" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "secret_secret" {
  name      = "/drone/server/amazon_secret"
  type      = "String"
  value     = random_string.secret_secret.result
  overwrite = true
}

module "drone_secrets_task" {
  source                             = "../task"
  service_name                       = "amazon-secrets"
  vpc_id                             = lookup(var.network, "vpc_id", null)
  vpc_private_subnets                = lookup(var.network, "vpc_private_subnets", null)
  task_name                          = "amazon-secrets"
  task_image                         = "drone/drone-amazon-secrets"
  task_image_version                 = lookup(var.server_versions, "secrets", null)
  task_container_log_group_name      = var.log_group_id
  container_registry                 = local.container_registry
  service_discovery_dns_namespace_id = module.drone_lb.service_discovery_private_dns_namespace_id
  service_cluster_name               = lookup(var.network, "cluster_name", null)
  service_cluster_id                 = lookup(var.network, "cluster_id", null)
  task_bind_port                     = 3000

  task_secret_vars = [
    {
      name      = "SECRET_KEY"
      valueFrom = aws_ssm_parameter.secret_secret.arn
    }
  ]

  task_environment_vars = [
    {
      name  = "DEBUG",
      value = "${var.drone_debug}"
    },
    {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }
  ]
}

resource "aws_iam_policy" "secrets_policy" {
  name = "secrets_taskj_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds",
        "kms:Decrypt"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "secret_task_custom" {
  role       = module.drone_secrets_task.task_role_id
  policy_arn = aws_iam_policy.secrets_policy.arn
}
