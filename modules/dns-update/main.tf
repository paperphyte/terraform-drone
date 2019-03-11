locals {
  cluster_arn            = "${var.cluster_arn}"
  task_domain_name       = "${var.task_domain_name}"
  route53_hosted_zone_id = "${var.route53_hosted_zone_id}"
  function_name          = "${var.function_name}"
  ecs_service_name       = "${var.ecs_service_name}"
  enabled                = "${var.module_is_disabled}"
}

resource "aws_lambda_function" "update_dns_on_state_change" {
  count            = "${local.enabled == false ? 1 : 0}"
  filename         = "${local.function_name}.zip"
  function_name    = "${local.function_name}"
  handler          = "update-dns.handler"
  runtime          = "nodejs8.10"
  publish          = true
  role             = "${aws_iam_role.update_dns_state_changer.arn}"
  source_code_hash = "${data.archive_file.update_dns_zip.output_base64sha256}"
}

data "template_file" "update_dns_on_state_change_lambda" {
  count = "${local.enabled == false ? 1 : 0}"

  template = "${file("${path.module}/templates/update-dns.js")}"

  vars {
    cluster_arn            = "${local.cluster_arn}"
    task_domain_name       = "${local.task_domain_name}"
    route53_hosted_zone_id = "${local.route53_hosted_zone_id}"
    ecs_service_name       = "${local.ecs_service_name}"
    function_name          = "${local.function_name}"
    domain_ttl             = "${var.domain_ttl}"
  }
}

data "archive_file" "update_dns_zip" {
  count = "${local.enabled == false ? 1 : 0}"

  type        = "zip"
  output_path = "${local.function_name}.zip"

  source {
    filename = "update-dns.js"
    content  = "${data.template_file.update_dns_on_state_change_lambda.rendered}"
  }
}

resource "aws_cloudwatch_log_group" "update_dns_log_group" {
  count = "${local.enabled == false ? 1 : 0}"

  name              = "/aws/lambda/${aws_lambda_function.update_dns_on_state_change.function_name}"
  retention_in_days = "${var.log_retention}"
}

data "template_file" "update_dns_state_changer_profile" {
  count = "${local.enabled == false ? 1 : 0}"

  template = "${file("${path.module}/templates/update-dns-policy.json")}"

  vars {
    log_group_arn = "${aws_cloudwatch_log_group.update_dns_log_group.arn}"
  }
}

resource "aws_iam_role" "update_dns_state_changer" {
  count = "${local.enabled == false ? 1 : 0}"

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

resource "aws_iam_role_policy" "update_dns_policy" {
  count = "${local.enabled == false ? 1 : 0}"

  role   = "${aws_iam_role.update_dns_state_changer.name}"
  policy = "${data.template_file.update_dns_state_changer_profile.rendered}"
}

data "template_file" "aws_cloudwatch_event_rule_pattern" {
  count = "${local.enabled == false ? 1 : 0}"

  template = "${file("${path.module}/templates/event-pattern.json")}"

  vars {
    cluster_arn = "${local.cluster_arn}"
  }
}

resource "aws_cloudwatch_event_rule" "update_dns_on_state_change" {
  count = "${local.enabled == false ? 1 : 0}"

  name          = "update-dns-${local.ecs_service_name}"
  description   = "Update dns for: ${local.ecs_service_name}"
  event_pattern = "${data.template_file.aws_cloudwatch_event_rule_pattern.rendered}"
}

resource "aws_cloudwatch_event_target" "lambda_function" {
  count = "${local.enabled == false ? 1 : 0}"

  rule      = "${aws_cloudwatch_event_rule.update_dns_on_state_change.name}"
  target_id = "${aws_lambda_function.update_dns_on_state_change.function_name}"
  arn       = "${aws_lambda_alias.update_dns_on_state_change_alias.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = "${local.enabled == false ? 1 : 0}"

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = "${aws_lambda_function.update_dns_on_state_change.function_name}"
  source_arn    = "${aws_cloudwatch_event_rule.update_dns_on_state_change.arn}"
  qualifier     = "${aws_lambda_alias.update_dns_on_state_change_alias.name}"
}

resource "aws_lambda_alias" "update_dns_on_state_change_alias" {
  count = "${local.enabled == false ? 1 : 0}"

  name             = "${var.function_name}-prod"
  description      = "${var.function_name} description"
  function_name    = "${aws_lambda_function.update_dns_on_state_change.function_name}"
  function_version = "$LATEST"
}
