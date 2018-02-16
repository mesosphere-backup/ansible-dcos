output "dns_resolvers" {
  value = "${var.dcos_resolvers}"
}

output "cluster_prefix" {
  value = "${data.template_file.cluster-name.rendered}"
}

output "bootstrap_public_ips" {
  value = "${google_compute_instance.bootstrap.network_interface.0.access_config.0.assigned_nat_ip}"

}

output "bootstrap_private_ips" {
  value = "${google_compute_instance.bootstrap.network_interface.0.address}"
}

output "lb_external_masters" {
  value = "${google_compute_forwarding_rule.external-master-forwarding-rule-http.ip_address}"
}

output "lb_internal_masters" {
  value = "${google_compute_forwarding_rule.internal-master-forwarding-rule.ip_address}"
}

output "master_public_ips" {
  value = ["${google_compute_instance.master.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "master_private_ips" {
  value = "${google_compute_instance.master.*.network_interface.0.address}"
}

output "agent_public_ips" {
  value = ["${google_compute_instance.agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "lb_external_agents" {
  value = "${google_compute_forwarding_rule.external-public-agent-forwarding-rule-http.ip_address}"
}

output "public_agent_public_ips" {
  value = ["${google_compute_instance.public-agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "dns_search" {
  value = "None"
}

output "ip_detect" {
  value = "gcp"
}
