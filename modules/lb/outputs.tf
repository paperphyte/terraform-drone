output "target_group_arn" {
  value = "${aws_alb_target_group.ci_server.id}"
}

output "url_443" {
  value = "https://${aws_acm_certificate.cert.domain_name}"
}
