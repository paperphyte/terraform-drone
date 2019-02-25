data "template_file" "ci_server_ecs_profile" {
  template = "${file("${path.module}/iam-policy/drone-ecs.json")}"

  vars {
    server_log_group_arn = "${aws_cloudwatch_log_group.drone_agent.arn}"
    agent_log_group_arn  = "${aws_cloudwatch_log_group.drone_server.arn}"
  }
}

resource "aws_iam_role" "ci_server_ecs_task" {
  name = "ci_server_ecs_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ci_server_ecs" {
  name   = "ci-server-ecs-policy"
  role   = "${aws_iam_role.ci_server_ecs_task.name}"
  policy = "${data.template_file.ci_server_ecs_profile.rendered}"
}
