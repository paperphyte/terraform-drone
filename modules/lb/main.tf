locals {
  sub_domain  = var.ci_sub_domain
  root_domain = var.root_domain
  subnet_id_1 = var.subnet_id_1
  subnet_id_2 = var.subnet_id_2
  vpc_id      = var.vpc_id
  enabled     = var.module_is_enabled
}

resource "aws_alb_target_group" "ci_server" {
  count = local.enabled == true ? 1 : 0

  name        = "ci-server-ecs"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path                = var.target_health_check_endpoint
    matcher             = "200"
    timeout             = "5"
    healthy_threshold   = "3"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb" "front" {
  count = local.enabled == true ? 1 : 0

  name            = "drone-front-alb"
  internal        = false
  security_groups = [aws_security_group.ci_server_web[0].id]
  subnets         = [local.subnet_id_1, local.subnet_id_2]

  enable_deletion_protection = false
  tags = {
    "Name" = "${local.sub_domain}.${local.root_domain}"
  }
}

resource "aws_alb_listener" "front_end" {
  count = local.enabled == true ? 1 : 0

  load_balancer_arn = aws_alb.front[0].id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"

  default_action {
    target_group_arn = aws_alb_target_group.ci_server[0].id
    type             = "forward"
  }
}

resource "aws_security_group" "ci_server_web" {
  count = local.enabled == true ? 1 : 0

  description = "Restrict access to ALB"

  vpc_id = local.vpc_id
  name   = "ci-server-alb-sg"
}

resource "aws_security_group_rule" "ci_server_web_egress" {
  count = local.enabled == true ? 1 : 0

  type        = "egress"
  description = "RDP s"
  depends_on  = [aws_security_group.ci_server_web]
  from_port   = 0
  to_port     = 0
  protocol    = "-1"

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  security_group_id = aws_security_group.ci_server_web[0].id
}

resource "aws_route53_record" "ci_public_url" {
  count = local.enabled == true ? 1 : 0

  zone_id = var.root_domain_zone_id
  name    = "${local.sub_domain}.${local.root_domain}"
  type    = "A"

  alias {
    name                   = aws_alb.front[0].dns_name
    zone_id                = aws_alb.front[0].zone_id
    evaluate_target_health = false
  }
}

resource "aws_security_group_rule" "ci_server_web_ingress" {
  count = local.enabled == true ? 1 : 0

  type        = "ingress"
  description = "Access to the drone server"
  depends_on  = [aws_security_group.ci_server_web]
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = var.ip_access_whitelist

  security_group_id = aws_security_group.ci_server_web[0].id
}

resource "aws_security_group_rule" "ci_server_web_ingress2" {
  count = local.enabled == true ? 1 : 0

  type        = "ingress"
  description = "Access during drone autocert"
  depends_on  = [aws_security_group.ci_server_web]
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  security_group_id = aws_security_group.ci_server_web[0].id
}

