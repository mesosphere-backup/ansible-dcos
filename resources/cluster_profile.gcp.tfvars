cluster_name = "ansible-dcos"
#
num_masters = "1"
num_private_agents = "3"
num_public_agents = "1"
#
tags={owner="username",expiration="8h"}
admin_ips = ["0.0.0.0/0"]
dcos_instance_os = "centos_7.3"
#
bootstrap_instance_type = "n1-standard-2"
masters_instance_type = "n1-standard-8"
private_agents_instance_type = "n1-standard-8"
public_agents_instance_type = "n1-standard-8"
#
ssh_public_key_file = ""