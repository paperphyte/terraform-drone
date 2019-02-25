resource "aws_alb_target_group" "ci_server" {
  name        = "ci-server-ecs"
  port        = "${var.drone_server_port}"
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.ci.id}"
  target_type = "ip"

  health_check {
    path                = "/healthz"
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
  subnets         = ["${aws_subnet.ci_subnet_a.id}", "${aws_subnet.ci_subnet_c.id}"]

  enable_deletion_protection = false
  tags                       = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
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
  name    = "${var.ci_sub_domain}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.front.dns_name}"
    zone_id                = "${aws_alb.front.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.ci_sub_domain}.${var.root_domain}"
  validation_method = "DNS"
  tags              = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
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
