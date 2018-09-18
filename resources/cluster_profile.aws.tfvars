cluster_name = "ansible-dcos"
#
num_masters = "1"
num_private_agents = "3"
num_public_agents = "1"
#
tags={Owner = "username", Expires = "8h"}
admin_ips = ["0.0.0.0/0"]
dcos_instance_os = "centos_7.4"
#
bootstrap_instance_type = "m4.large"
masters_instance_type = "m4.2xlarge"
private_agents_instance_type = "m4.2xlarge"
public_agents_instance_type = "m4.2xlarge"
#
aws_region = "us-west-2"
aws_profile = ""
aws_key_name = ""
ssh_public_key_file = ""