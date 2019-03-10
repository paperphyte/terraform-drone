output "deployed_version" {
  value = "${aws_lambda_function.update_dns_on_state_change.version}"
}
