resource "aws_security_group" "ci_server_web" {
  description = "Restrict access to ALB"

  vpc_id = "${aws_vpc.ci.id}"
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
  depends_on  = ["aws_security_group.ci_server_app", "aws_security_group.ci_server_web"]
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = "${var.alb_ingres_cidr_whitelist}"

  security_group_id = "${aws_security_group.ci_server_web.id}"
}

resource "aws_security_group" "ci_server_app" {
  description = "Restrict access to application server."
  vpc_id      = "${aws_vpc.ci.id}"
  name        = "ci-server-task-sg"
}

resource "aws_security_group_rule" "ci_server_app_egress" {
  type        = "egress"
  description = "RDP c"
  depends_on  = ["aws_security_group.ci_server_app"]
  from_port   = 0
  to_port     = 0
  protocol    = "-1"

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  security_group_id = "${aws_security_group.ci_server_app.id}"
}

resource "aws_security_group_rule" "ci_server_app_ingress" {
  type        = "ingress"
  description = "RDP n"
  depends_on  = ["aws_security_group.ci_server_app", "module.ci_ecs_cluster"]
  protocol    = "tcp"
  from_port   = "${var.drone_agent_port}"
  to_port     = "${var.drone_agent_port}"

  source_security_group_id = "${module.ci_ecs_cluster.cluster_instance_security_group_id}"
  security_group_id        = "${aws_security_group.ci_server_app.id}"
}

resource "aws_security_group_rule" "ci_server_app_ingress2" {
  type        = "ingress"
  description = "RDP v"
  depends_on  = ["aws_security_group.ci_server_app", "aws_security_group.ci_server_web"]
  protocol    = "tcp"
  from_port   = "${var.drone_server_port}"
  to_port     = "${var.drone_server_port}"

  source_security_group_id = "${aws_security_group.ci_server_web.id}"
  security_group_id        = "${aws_security_group.ci_server_app.id}"
}
