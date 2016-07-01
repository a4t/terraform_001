variable "deploy_sg"    {}
variable "vpc_id"       {}
variable "app_sg_count" {}
variable "app_sg_list"  { default = [] }

resource "aws_security_group_rule" "attach" {
  count = "${var.app_sg_count}"

  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  source_security_group_id = "${var.deploy_sg}"

  security_group_id = "${element(var.app_sg_list, count.index)}"
}