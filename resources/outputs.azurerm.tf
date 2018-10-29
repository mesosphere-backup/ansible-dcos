output "dns_resolvers" {
  value = ["168.63.129.16"]
}

output "cluster_prefix" {
  value = "${var.cluster_name}"
}

output "bootstrap_public_ips" {
  value = "${module.dcos-infrastructure.bootstrap.public_ip[0]}"
}

output "bootstrap_private_ips" {
  value = "${module.dcos-infrastructure.bootstrap.private_ip[0]}"
}

output "lb_external_masters" {
  value = "${module.dcos-infrastructure.lb.masters}"
}

output "lb_internal_masters" {
  value = "${module.dcos-infrastructure.lb.masters-internal}"
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
  value = "${module.dcos-infrastructure.lb.public-agents}"
}

output "public_agent_public_ips" {
  value = ["${module.dcos-infrastructure.public_agents.public_ips}"]
}

output "bootstrap_admin_username" {
  value = "${module.dcos-infrastructure.bootstrap.admin_username}"
}

output "masters_admin_username" {
  value = "${module.dcos-infrastructure.masters.admin_username}"
}

output "public_agents_admin_username" {
  value = "${module.dcos-infrastructure.public_agents.admin_username}"
}

output "private_agents_admin_username" {
  value = "${module.dcos-infrastructure.private_agents.admin_username}"
}

output "dns_search" {
  value = "None"
}

output "ip_detect" {
  value = "azure"
}

