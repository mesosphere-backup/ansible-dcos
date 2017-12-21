output "dns_resolvers" {
  value = "${var.dcos_resolvers}"
}

output "cluster_prefix" {
  value = "${data.template_file.cluster-name.rendered}"
}

output "bootstrap_public_ips" {
  value = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
}

output "bootstrap_private_ips" {
  value = "${azurerm_network_interface.bootstrap_nic.private_ip_address}"
}

output "lb_external_masters" {
  value = "${azurerm_public_ip.master_load_balancer_public_ip.fqdn}"
}

output "lb_internal_masters" {
  value = "${azurerm_lb.master_internal_load_balancer.private_ip_address}"
}

output "master_public_ips" {
  value = ["${azurerm_public_ip.master_public_ip.*.fqdn}"]
}

output "master_private_ips" {
  value = "${azurerm_network_interface.master_nic.*.private_ip_address}"
}

output "agent_public_ips" {
  value = ["${azurerm_public_ip.agent_public_ip.*.fqdn}"]
}

output "lb_external_agents" {
  value = "${azurerm_public_ip.public_agent_load_balancer_public_ip.fqdn}"
}

output "public_agent_public_ips" {
  value = ["${azurerm_public_ip.public_agent_public_ip.*.fqdn}"]
}

output "dns_search" {
  value = "None"
}

output "ip_detect" {
  value = "azure"
}
