output "dns_resolvers" {
  value = ["172.12.0.2"]
}

output "cluster_prefix" {
  value = "${var.cluster_name}"
}

output "bootstrap_public_ips" {
  value = "${module.dcos-infrastructure.bootstrap.public_ip}"
}

output "bootstrap_private_ips" {
  value = "${module.dcos-infrastructure.bootstrap.private_ip}"
}

output "lb_external_masters" {
  value = "${module.dcos-infrastructure.elb.masters_dns_name}"
}

output "lb_internal_masters" {
  value = "${module.dcos-infrastructure.elb.masters_internal_dns_name}"
}

output "master_public_ips" {
  value = ["${module.dcos-infrastructure.masters.public_ips}"]
}

output "master_private_ips" {
  value = "${module.dcos-infrastructure.masters.private_ips}"
}

output "agent_public_ips" {
  value = ["${module.dcos-infrastructure.private_agents.public_ips}"]
}

output "lb_external_agents" {
  value = "${module.dcos-infrastructure.elb.public_agents_dns_name}"
}

output "public_agent_public_ips" {
  value = ["${module.dcos-infrastructure.public_agents.public_ips}"]
}

output "dns_search" {
  value = "${var.aws_region}.compute.internal"
}

output "ip_detect" {
  value = "aws"
}
