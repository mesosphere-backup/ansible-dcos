## Steps for manual installation (not using terraform)

- Execute `ssh-add {keypair}.pem` for accessing your cluster nodes

- Copy `./hosts.example` to `./hosts` and fill in the (public) IP addresses of your cluster. For example:

```
[workstations]
1.0.0.1

[masters]
1.0.0.2

[agents]
1.0.0.3
1.0.0.4

[agents_public]
1.0.0.5

[common:children]
workstations
masters
agents
agents_public
```

- Copy the directory `group_vars/all.example` to `group_vars/all`.

- Within the file `group_vars/all/networking.yaml` you have to define all the (internal/private) IPs of your Cluster. An example is listed below:

```
---
# Choose the IP Detect Script
# options: eth0, eth1, aws, gce
ip_detect: aws

# (internal) IP Address of the Workstation
workstation_ip: 1.0.0.1

# (internal) IP Addresses for the Master Nodes
master_list: |
  - 1.0.0.2

# DNS Resolvers
resolvers: |
  - 8.8.4.4
  - 8.8.8.8

# DNS Search Domain
dns_search: None

# Internal Loadbalancer DNS for Masters
exhibitor_address: masterlb.internal
```

- There is another file called `group_vars/all/setup.yaml`. This file is for configuring DC/OS. You have to fill in the variables that match your preferred configuration. The variables are explained within the example below:

```
---
# Name of the DC/OS Cluster
cluster_name: demo

# Download URL for DC/OS
dcos_download: https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh

# Install latest operating system updates
# options: true, false
system_updates: true

# Configuration for the Exhibitor Storage Backend
# options: aws_s3, static
exhibitor: static

# AWS S3 Credentials (only needed for exhibitor: aws_s3)
aws_access_key_id: "******"
aws_secret_access_key: "******"
aws_region: us-west-2
s3_bucket: bucket-name

# Enterprise or OSS?
enterprise_dcos: false

# This parameter specifies your desired security mode. (only for Mesosphere Enterprise DC/OS)
# options: disabled, permissive, strict
security: permissive

# Configure rexray to enable support of external volumes (only for Mesosphere Enterprise DC/OS)
# Note: Set rexray_config_method: file and edit ./roles/workstation/templates/rexray.yaml.j2 for a custom rexray configuration
# options: empty, file
rexray_config_method: empty

# Customer Key (only for Mesosphere Enterprise DC/OS)
customer_key: "########-####-####-####-############"

# DC/OS credentials (only for Mesosphere Enterprise DC/OS)
superuser_username: admin
superuser_password_hash: "$6$rounds=656000$8CXbMqwuglDt3Yai$ZkLEj8zS.GmPGWt.dhwAv0.XsjYXwVHuS9aHh3DMcfGaz45OpGxC5oQPXUUpFLMkqlXCfhXMloIzE0Xh8VwHJ." # Password: admin
```

- Run `ansible all -m ping` to check SSH connectivity

- Run `ansible-playbook install.yml` to apply the Ansible playbook
