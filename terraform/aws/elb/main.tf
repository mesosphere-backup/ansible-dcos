variable "prefix" {}
variable "owner" {}
variable "expiration" {}
variable "subnets" { type = "list" }
variable "security_groups_internal_masters" { type = "list" }
variable "security_groups_external_masters" { type = "list" }
variable "security_groups_external_agents" { type = "list" }
variable "master_instances" { type = "list" }
variable "public_agent_instances" { type = "list" }

resource "aws_elb" "internal_masters" {
  name = "${var.prefix}-internal-masters"

  internal = true
  subnets = ["${var.subnets}"]
  security_groups = ["${var.security_groups_internal_masters}"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 2181
    instance_protocol = "tcp"
    lb_port           = 2181
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 5050
    instance_protocol = "http"
    lb_port           = 5050
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8181
    instance_protocol = "http"
    lb_port           = 8181
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:5050"
    interval            = 30
  }

  instances                   = ["${var.master_instances}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 60
  connection_draining         = false

  tags {
          Name = "${var.prefix}-internal-masters"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }
}

resource "aws_elb" "external_masters" {
  name = "${var.prefix}-external-masters"

  internal = false
  subnets = ["${var.subnets}"]
  security_groups = ["${var.security_groups_external_masters}"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:5050"
    interval            = 30
  }

  instances                   = ["${var.master_instances}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 60
  connection_draining         = false

  tags {
          Name = "${var.prefix}-external-masters"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }
}

resource "aws_elb" "external_agents" {
  name = "${var.prefix}-external-agents"

  internal = false
  subnets = ["${var.subnets}"]
  security_groups = ["${var.security_groups_external_agents}"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:9090/_haproxy_health_check"
    interval            = 5
  }

  instances                   = ["${var.public_agent_instances}"]
  cross_zone_load_balancing   = false
  idle_timeout                = 60
  connection_draining         = false

  tags {
          Name = "${var.prefix}-external-agents"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }
}

output "external_masters_dns_name" {
  value = "${aws_elb.external_masters.dns_name}"
}

output "internal_masters_dns_name" {
  value = "${aws_elb.internal_masters.dns_name}"
}

output "external_agents_dns_name" {
  value = "${aws_elb.internal_masters.dns_name}"
}
