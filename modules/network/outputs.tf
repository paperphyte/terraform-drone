output "subnet_id_1" {
  value = "${aws_subnet.ci_subnet_a.id}"
}

output "subnet_id_2" {
  value = "${aws_subnet.ci_subnet_c.id}"
}

output "vpc_id" {
  value = "${aws_vpc.ci.id}"
}

output "vpc_arn" {
  value = "${aws_vpc.ci.arn}"
}
