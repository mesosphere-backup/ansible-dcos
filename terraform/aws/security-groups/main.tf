variable "prefix" {}
variable "admin_ip" {}
variable "subnet_range" {}
variable "vpc_id" {}

resource "aws_security_group" "internal_sg" {
  name = "${var.prefix}-internal-sg"
  description = "Allow all internal traffic"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.subnet_range}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "lb_masters_sg" {
  name = "${var.prefix}-lb-masters-sg"
  description = "Allow incoming traffic on Masters LB"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

}

resource "aws_security_group" "lb_agents_sg" {
  name = "${var.prefix}-lb-agents-sg"
  description = "Allow incoming traffic on Public Agents LB"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "admin_sg" {
  name = "${var.prefix}-admin-sg"
  description = "Allow incoming traffic from admin_ip"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

  ingress {
    from_port = 8181
    to_port = 8181
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

  ingress {
    from_port = 9090
    to_port = 9090
    protocol = "tcp"
    cidr_blocks = ["${var.admin_ip}"]
  }

  # TODO: Define additional ports for debugging
}

output "internal_sg" {
  value = "${aws_security_group.internal_sg.id}"
}

output "lb_masters_sg" {
  value = "${aws_security_group.lb_masters_sg.id}"
}

output "lb_agents_sg" {
  value = "${aws_security_group.lb_agents_sg.id}"
}

output "admin_sg" {
  value = "${aws_security_group.admin_sg.id}"
}
