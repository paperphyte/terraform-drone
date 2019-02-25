resource "aws_ecs_cluster" "ci_server" {
  name = "ci_server"
}

resource "aws_autoscaling_group" "ci_server_drone_agent" {
  name                 = "ci-server-drone-agent"
  vpc_zone_identifier  = ["${aws_subnet.ci_subnet_a.id}", "${aws_subnet.ci_subnet_c.id}"]
  min_size             = "${var.ci_ecs_min_instances_count}"
  max_size             = "${var.ci_ecs_max_instances_count}"
  desired_capacity     = "${var.ci_ecs_min_instances_count}"
  launch_configuration = "${aws_launch_configuration.ci_server_app.name}"

  tags = [
    {
      key                 = "Name"
      value               = "${var.ci_sub_domain}.${var.root_domain}"
      propagate_at_launch = true
    },
  ]
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/cloud-config.yml")}"

  vars {
    ecs_cluster_name = "${aws_ecs_cluster.ci_server.name}"
  }
}

data "aws_ami" "amazon_linux_2" {
  filter {
    name   = "image-id"
    values = ["${lookup(var.ecs_optimized_ami, var.aws_region)}"]
  }
}

resource "aws_key_pair" "ci_tool" {
  key_name   = "ci-tools"
  public_key = "${var.ci_tool_pubkey}"
}

resource "aws_launch_configuration" "ci_server_app" {
  security_groups = [
    "${aws_security_group.ci_server_ecs_instance.id}",
  ]

  key_name                    = "${aws_key_pair.ci_tool.key_name}"
  image_id                    = "${data.aws_ami.amazon_linux_2.id}"
  instance_type               = "${var.ci_ec2_instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.ci_server.name}"
  user_data                   = "${data.template_file.cloud_config.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size = "100"
  }
}
