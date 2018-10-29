output "dns_resolvers" {
  value = ["169.254.169.254"]
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
  value = "${module.dcos-infrastructure.forwarding_rules.masters}"
}

output "lb_internal_masters" {
  value = "None"
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
  value = "${module.dcos-infrastructure.forwarding_rules.public_agents}"
}

output "public_agent_public_ips" {
  value = ["${module.dcos-infrastructure.public_agents.public_ips}"]
}

output "bootstrap_admin_username" {
  value = "${module.dcos-infrastructure.bootstrap.ssh_user}"
}

output "masters_admin_username" {
  value = "${module.dcos-infrastructure.masters.ssh_user}"
}

output "public_agents_admin_username" {
  value = "${module.dcos-infrastructure.public_agents.ssh_user}"
}

output "private_agents_admin_username" {
  value = "${module.dcos-infrastructure.private_agents.ssh_user}"
}

output "dns_search" {
  value = "google.internal"
}

output "ip_detect" {
  value = "gcp"
}

