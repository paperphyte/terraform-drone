locals {
  sub_domain  = "${var.ci_sub_domain}"
  root_domain = "${var.root_domain}"
  subnet_id_1 = "${var.subnet_id_1}"
  subnet_id_2 = "${var.subnet_id_2}"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_alb_target_group" "ci_server" {
  name        = "ci-server-ecs"
  port        = "${var.target_port}"
  protocol    = "HTTP"
  vpc_id      = "${local.vpc_id}"
  target_type = "ip"

  health_check {
    path                = "${var.target_health_check_endpoint}"
    matcher             = "200"
    timeout             = "5"
    healthy_threshold   = "3"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb" "front" {
  name            = "drone-front-alb"
  internal        = false
  security_groups = ["${aws_security_group.ci_server_web.id}"]
  subnets         = ["${local.subnet_id_1}", "${local.subnet_id_2}"]

  enable_deletion_protection = false
  tags                       = "${map("Name", "${local.sub_domain}.${local.root_domain}")}"
}

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.front.id}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.ci_server.id}"
    type             = "forward"
  }
}

resource "aws_route53_record" "ci_public_url" {
  zone_id = "${var.root_domain_zone_id}"
  name    = "${local.sub_domain}.${local.root_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.front.dns_name}"
    zone_id                = "${aws_alb.front.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${local.sub_domain}.${local.root_domain}"
  validation_method = "DNS"
  tags              = "${map("Name", "${local.sub_domain}.${local.root_domain}")}"
  provider          = "aws"
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = "${aws_acm_certificate.cert.arn}"
  provider        = "aws"

  validation_record_fqdns = [
    "${aws_route53_record.cert_validation.*.fqdn}",
  ]
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.root_domain_zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = "${var.default_ttl}"
}

resource "aws_security_group" "ci_server_web" {
  description = "Restrict access to ALB"

  vpc_id = "${local.vpc_id}"
  name   = "ci-server-alb-sg"
}

resource "aws_security_group_rule" "ci_server_web_egress" {
  type        = "egress"
  description = "RDP s"
  depends_on  = ["aws_security_group.ci_server_web"]
  from_port   = 0
  to_port     = 0
  protocol    = "-1"

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  security_group_id = "${aws_security_group.ci_server_web.id}"
}

resource "aws_security_group_rule" "ci_server_web_ingress" {
  type        = "ingress"
  description = "RDP p"
  depends_on  = ["aws_security_group.ci_server_web"]
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = "${var.ip_access_whitelist}"

  security_group_id = "${aws_security_group.ci_server_web.id}"
}
