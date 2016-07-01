resource "aws_vpc" "vpc" {
  cidr_block           = "172.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}