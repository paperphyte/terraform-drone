
#-----------------------------------
# Security Group rules for runner
#-----------------------------------
resource "aws_security_group" "runner" {
  description = "Restrict access to drone_runner."
  vpc_id      = local.vpc_id
  name        = "drone-runner-sg"
}

resource "aws_security_group_rule" "runner_default_egress" {
  type              = "egress"
  description       = "Outgoing service traffic rule"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.runner.id
}

#-----------------------------------
# Access from Drone runner to server
#-----------------------------------

resource "aws_security_group_rule" "runner_ingress" {
  type        = "ingress"
  description = "Drone CI/CD build agents to access"
  protocol    = "tcp"
  from_port   = var.runner_port
  to_port     = var.runner_port

  source_security_group_id = var.runner_security_group_id
  security_group_id        = var.server_security_group_id
}