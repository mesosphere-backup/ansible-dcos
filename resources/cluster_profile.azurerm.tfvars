cluster_name = "ansible-dcos"
#
num_masters = "1"
num_private_agents = "3"
num_public_agents = "1"
#
tags={Owner = "username", Expires = "8h"}
admin_ips = ["0.0.0.0/0"]
dcos_instance_os = "centos_7.3"
#
bootstrap_instance_type = "Standard_B2s"
masters_instance_type = "Standard_D4s_v3"
private_agents_instance_type = "Standard_D4s_v3"
public_agents_instance_type = "Standard_D4s_v3"
#
location = "West US"
ssh_public_key_file = ""