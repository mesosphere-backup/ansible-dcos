variable "subnet_range" {}
variable "azs" { type = "map"}
variable "region" {}
variable "prefix" {}

# Create a VPC to launch our instances into
resource "aws_vpc" "dcos_vpc" {
  cidr_block = "${var.subnet_range}"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create a subnet to launch our instances into
resource "aws_subnet" "dcos_subnet" {

  vpc_id = "${aws_vpc.dcos_vpc.id}"
  count             = "${length(split(",", lookup(var.azs, var.region)))}"
  cidr_block        = "${cidrsubnet(var.subnet_range, 4, count.index)}"
  availability_zone = "${element(split(",", lookup(var.azs, var.region)), count.index)}"

  map_public_ip_on_launch = true

  tags {
      "Name" = "${var.prefix}-${element(split(",", lookup(var.azs, var.region)), count.index)}-sn"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.dcos_vpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.dcos_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

output "subnets" {
  value = ["${aws_subnet.dcos_subnet.*.id}"]
}

output "vpc_id" {
  value = "${aws_vpc.dcos_vpc.id}"
}
