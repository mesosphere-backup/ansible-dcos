variable "amis" { type = "map" }
variable "region" {}
variable "azs" { type = "map" }
variable "instance_count" {}
variable "instance_name" {}
variable "key_name" {}
variable "vpc_security_group_ids" { type = "list" }
variable "subnet_id" {}
variable "instance_type" {}
variable "volume_size" {}
variable "owner" {}
variable "expiration" {}
variable "iam_instance_profile" {}

resource "aws_instance" "instance" {
  instance_type = "${var.instance_type}"
  ami = "${lookup(var.amis, var.region)}"

  count = "${var.instance_count}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  associate_public_ip_address = true
  iam_instance_profile = "${var.iam_instance_profile}"

  availability_zone = "${element(split(",", lookup(var.azs, var.region)), 0)}"
  subnet_id = "${var.subnet_id}"

  tags {
          Name = "${var.instance_name}-${count.index}"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }

  root_block_device {
    volume_size = "${var.volume_size}"
    delete_on_termination = true
  }

}

output "instances" {
  value = ["${aws_instance.instance.*.id}"]
}

output "public_ips" {
  value = "${join("\n", aws_instance.instance.*.public_ip)}"
}

output "private_ips" {
  value = "${join("\n  - ", aws_instance.instance.*.private_ip)}"
}
