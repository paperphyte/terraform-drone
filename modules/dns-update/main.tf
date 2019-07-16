locals {
  cluster_arn            = var.cluster_arn
  task_domain_name       = var.task_domain_name
  route53_hosted_zone_id = var.route53_hosted_zone_id
  function_name          = var.function_name
  ecs_service_name       = var.ecs_service_name
  vpc_arn                = var.vpc_arn
}

resource "aws_lambda_function" "update_dns_on_state_change" {
  filename         = "${local.function_name}.zip"
  function_name    = local.function_name
  handler          = "update-dns.handler"
  runtime          = "nodejs8.10"
  publish          = true
  role             = aws_iam_role.update_dns_state_changer.arn
  source_code_hash = data.archive_file.update_dns_zip.output_base64sha256
}

data "archive_file" "update_dns_zip" {

  type        = "zip"
  output_path = "${local.function_name}.zip"

  source {
    filename = "update-dns.js"
    content = templatefile("${path.module}/templates/update-dns.js", {
      cluster_arn            = local.cluster_arn,
      task_domain_name       = local.task_domain_name,
      route53_hosted_zone_id = local.route53_hosted_zone_id,
      ecs_service_name       = local.ecs_service_name,
      function_name          = local.function_name,
      domain_ttl             = var.domain_ttl
    })
  }
}

resource "aws_cloudwatch_log_group" "update_dns_log_group" {

  name              = "/aws/lambda/${aws_lambda_function.update_dns_on_state_change.function_name}"
  retention_in_days = var.log_retention
}

resource "aws_iam_role_policy" "update_dns_policy" {

  role = aws_iam_role.update_dns_state_changer.name
  policy = templatefile("${path.module}/templates/update-dns-policy.json", { log_group_arn = aws_cloudwatch_log_group.update_dns_log_group.arn, hosted_zone_id = local.route53_hosted_zone_id, vpc_arn = local.vpc_arn })
}

resource "aws_cloudwatch_event_rule" "update_dns_on_state_change" {

  name = "update-dns-${local.ecs_service_name}"
  description = "Update dns for: ${local.ecs_service_name}"
  event_pattern = templatefile("${path.module}/templates/event-pattern.json", { cluster_arn = local.cluster_arn })
}

resource "aws_cloudwatch_event_target" "lambda_function" {

  rule = aws_cloudwatch_event_rule.update_dns_on_state_change.name
  target_id = aws_lambda_function.update_dns_on_state_change.function_name
  arn = aws_lambda_alias.update_dns_on_state_change_alias.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {

  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"
  function_name = aws_lambda_function.update_dns_on_state_change.function_name
  source_arn = aws_cloudwatch_event_rule.update_dns_on_state_change.arn
  qualifier = aws_lambda_alias.update_dns_on_state_change_alias.name
}

resource "aws_lambda_alias" "update_dns_on_state_change_alias" {

  name = "${var.function_name}-prod"
  description = "${var.function_name} description"
  function_name = aws_lambda_function.update_dns_on_state_change.function_name
  function_version = "$LATEST"
}

resource "aws_iam_role" "update_dns_state_changer" {

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}