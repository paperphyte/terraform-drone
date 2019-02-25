resource "random_string" "drone_rpc_secret" {
  length  = 32
  special = false
}

resource "aws_cloudwatch_log_group" "drone_server" {
  name = "drone/server"
  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

data "template_file" "drone_server_task_definition" {
  template   = "${file("${path.module}/task-definitions/drone-server.json")}"
  depends_on = ["random_string.drone_rpc_secret"]

  vars {
    ci_db_host_name           = "${aws_db_instance.ci_db.address}"
    ci_db_user                = "${var.ci_db_username}"
    ci_db_password            = "${random_string.ci_db_password.result}"
    ci_db_engine              = "${var.ci_db_engine}"
    ci_db_port                = "${lookup(var.ci_db_engine_port, var.ci_db_engine)}"
    container_cpu             = "${var.fargate_task_cpu}"
    container_memory          = "${var.fargate_task_memory}"
    log_group_region          = "${var.aws_region}"
    log_group_drone_server    = "${aws_cloudwatch_log_group.drone_server.name}"
    drone_github_client       = "${var.env_github_client}"
    drone_github_secret       = "${var.env_github_secret}"
    drone_admin               = "${var.env_drone_admin}"
    drone_github_organization = "${var.env_drone_github_organization}"
    drone_version             = "${var.drone_version}"
    drone_server_port         = "${var.drone_server_port}"
    drone_rpc_server          = "${var.ci_sub_domain}.${var.root_domain}"
    drone_rpc_secret          = "${random_string.drone_rpc_secret.id}"
    drone_webhook_list        = "${var.env_drone_webhook_list}"
    drone_logs_debug          = "${var.env_drone_logs_debug}"
    drone_repository_filter   = "${var.env_drone_repo_filter}"
  }
}

resource "aws_ecs_task_definition" "drone_server" {
  family                   = "drone-server"
  container_definitions    = "${data.template_file.drone_server_task_definition.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  task_role_arn      = "${aws_iam_role.ci_server_ecs_task.arn}"
  execution_role_arn = "${aws_iam_role.ci_server_ecs_task.arn}"

  cpu    = "${var.fargate_task_cpu}"
  memory = "${var.fargate_task_memory}"
  tags   = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_ecs_service" "drone_server" {
  name            = "ci-server-drone-server"
  cluster         = "${aws_ecs_cluster.ci_server.id}"
  task_definition = "${aws_ecs_task_definition.drone_server.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = ["aws_ecs_task_definition.drone_server"]

  network_configuration {
    security_groups  = ["${aws_security_group.ci_server_app.id}"]
    subnets          = ["${aws_subnet.ci_subnet_a.id}", "${aws_subnet.ci_subnet_c.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.ci_server.id}"
    container_name   = "ci-server-drone-server"
    container_port   = "${var.drone_server_port}"
  }

  service_registries {
    registry_arn = "${aws_service_discovery_service.ci_server.arn}"
  }

  depends_on = [
    "aws_alb_listener.front_end",
  ]
}
