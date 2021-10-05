data "aws_route53_zone" "root_zone" {
  name         = var.dns_root_name
  private_zone = false
}
