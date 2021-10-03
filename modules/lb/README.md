# Readme

Module Creates a load balancer with ssl certificate and rules for ssl.
## Argument Reference

 * ```vcp_id``` ID of vpc
 * ```vcp_public_subnets``` Public subnets to create lb in
 * ```dns_root_name``` Domain name of root zone such as "example.com"
 * ```dns_hostname``` Host name of lb such as "myhost"
 * ```target_port``` Port for target group
 * ```target_health_check``` Target health check

## Attribute Reference

 * ```lb_sg_id``` ID of security group
 * ```fqdn``` Fully qualified domain name of lb such as "myhost.example.com"
 * ```lb_target_group_id```Target group id 
 * ```lb_id``` ID of loadbalancer
 
 ## Using the module

```hcl
module "example_lb" {
  source              = "./modules/lb"
  vpc_id              = module.vpc.vpc_id
  vpc_public_subnets  = module.vpc.public_subnets
  dns_root_name       = "example.com"
  dns_hostname        = "myhost"
  target_port         = 80
  target_health_check = {
    path                = "/health"
    matcher             = "200"
    timeout             = 30
    interval            = 60
    healthy_threshold   = "3"
    unhealthy_threshold = "2"
  }
}

resource "aws_security_group_rule" "lbingress" {
  type              = "ingress"
  description       = "Incoming"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.example_lb.lb_sg_id
}
```