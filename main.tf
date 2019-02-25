module "ci_db" {
  source                          = "./modules/database"
  db_identifier                   = "${var.ci_db_identifier}"
  db_storage                      = "${var.ci_db_storage}"
  db_instance_class               = "${var.ci_db_instance_class}"
  db_name                         = "${var.ci_db_name}"
  db_username                     = "${var.ci_db_username}"
  ci_sub_domain                   = "${var.ci_sub_domain}"
  root_domain                     = "${var.root_domain}"
  vpc_id                          = "${aws_vpc.ci.id}"
  subnet_id_1                     = "${aws_subnet.ci_subnet_a.id}"
  subnet_id_2                     = "${aws_subnet.ci_subnet_c.id}"
  ci_server_app_security_group_id = "${aws_security_group.ci_server_app.id}"
}
