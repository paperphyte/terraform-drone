output "deployed_version" {
  value = "${join("", aws_lambda_function.update_dns_on_state_change.*.version)}"
}
