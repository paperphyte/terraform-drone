# ----------------------------------------
# AWS Security Group
# ----------------------------------------
resource "aws_security_group" "lb" {
  description = "Traffic from web to ${var.dns_hostname} loadbalancer"
  name        = "${var.dns_hostname}-lb-sg"
  vpc_id      = lookup(var.network, "vpc_id")
}

resource "aws_security_group_rule" "lb_egress" {
  type              = "egress"
  description       = "Outgoing"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_ingress" {
  type              = "ingress"
  description       = "Incoming"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

# ----------------------------------------
# AWS Loadbalancer
# ----------------------------------------
resource "aws_lb" "lb" {
  name            = "${var.dns_hostname}-lb"
  security_groups = [aws_security_group.lb.id]
  subnets         = lookup(var.network, "vpc_public_subnets")

}

resource "aws_route53_record" "lb_public_url" {
  zone_id = lookup(var.network, "dns_root_id")
  name    = "${var.dns_hostname}.${lookup(var.network, "dns_root_name")}"
  type    = "A"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
  allow_overwrite = true
}

resource "aws_lb_listener" "https_redirect" {
  load_balancer_arn = aws_lb.lb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "lb" {
  name        = "${var.dns_hostname}-target-group"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = lookup(var.network, "vpc_id")
  target_type = "ip"

  dynamic "health_check" {
    for_each = [var.target_health_check]
    content {
      path                = health_check.value["path"]
      matcher             = health_check.value["matcher"]
      timeout             = health_check.value["timeout"]
      interval            = health_check.value["interval"]
      healthy_threshold   = health_check.value["healthy_threshold"]
      unhealthy_threshold = health_check.value["unhealthy_threshold"]
    }
  }
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    target_group_arn = aws_lb_target_group.lb.id
    type             = "forward"
  }
}

# ----------------------------------------
# AWS Certificate
# ----------------------------------------
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.dns_hostname}.${lookup(var.network, "dns_root_name")}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = lookup(var.network, "dns_root_id")
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ----------------------------------------
# Local private service discovery namespace
# ----------------------------------------

resource "aws_service_discovery_private_dns_namespace" "private_dns_namespace" {
  name        = "${var.dns_hostname}.local"
  description = "Private paperphyte-tools DNS"
  vpc         = lookup(var.network, "vpc_id")
}
