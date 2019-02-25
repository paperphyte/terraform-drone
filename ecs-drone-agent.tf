resource "aws_cloudwatch_log_group" "drone_agent" {
  name = "drone/agent"
  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "random_pet" "drone_task_runnner_name" {
  separator = "."
}

data "template_file" "drone_agent_task_definition" {
  template   = "${file("task-definitions/drone-agent.json")}"
  depends_on = ["random_string.drone_rpc_secret"]

  vars {
    log_group_region      = "${var.aws_region}"
    log_group_drone_agent = "${aws_cloudwatch_log_group.drone_agent.name}"
    runner_name           = "${random_pet.drone_task_runnner_name.id}"
    drone_rpc_server      = "http://${aws_service_discovery_service.ci_server.name}.${aws_service_discovery_private_dns_namespace.ci.name}"
    drone_rpc_secret      = "${random_string.drone_rpc_secret.id}"
    drone_version         = "${var.drone_version}"
    container_cpu         = "${var.ecs_container_cpu}"
    container_memory      = "${var.ecs_container_memory}"
    drone_logs_debug      = "${var.env_drone_logs_debug}"
  }
}

resource "aws_ecs_task_definition" "drone_agent" {
  family                = "drone-agent"
  container_definitions = "${data.template_file.drone_agent_task_definition.rendered}"

  volume {
    name      = "dockersock"
    host_path = "/var/run/docker.sock"
  }

  tags = "${map("Name", "${var.ci_sub_domain}.${var.root_domain}")}"
}

resource "aws_ecs_service" "drone_agent" {
  name = "drone-agent"

  depends_on = [
    "aws_ecs_task_definition.drone_agent",
  ]

  cluster         = "${module.ci_ecs_cluster.id}"
  desired_count   = "${var.drone_agent_max_count}"
  task_definition = "${aws_ecs_task_definition.drone_agent.arn}"
}

resource "aws_appautoscaling_target" "drone_agent" {
  max_capacity       = "${var.drone_agent_max_count}"
  min_capacity       = "${var.drone_agent_min_count}"
  resource_id        = "service/${module.ci_ecs_cluster.name}/${aws_ecs_service.drone_agent.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
