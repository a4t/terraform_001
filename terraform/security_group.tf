resource "aws_security_group" "app1" {
  name = "app1"
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group" "app2" {
  name = "app2"
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group" "app3" {
  name = "app3"
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_security_group" "deploy" {
  name = "deploy"
  vpc_id = "${aws_vpc.vpc.id}"
}

module "security_group" {
  source = "./modules/security_group"

  vpc_id       = "${aws_vpc.vpc.id}"
  deploy_sg    = "${aws_security_group.deploy.id}"

  app_sg_count = "3"
  app_sg_list  = [
    "${aws_security_group.app1.id}",
    "${aws_security_group.app2.id}",
    "${aws_security_group.app3.id}"
  ]
}
