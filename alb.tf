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
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.ci_server.id}"
    type             = "forward"
  }
}
