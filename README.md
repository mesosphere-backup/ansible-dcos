# ansible-dcos

Updated for 1.8.x!

This ansible playbook installs DC/OS and should run on CentOS/RHEL 7. The installation steps are based on the [Advanced Installation Guide](https://docs.mesosphere.com/latest/administration/installing/custom/advanced/) of DC/OS.

## (Optional) Create CentOS machines in AWS, using Terraform and Ansible

This repo includes the Terraform script `terraform/aws.tf.template` to create the CentOS machines to run the Ansible script on. This script is just for testing purposes and you don't have to use it.

- {on a mac} `brew install terraform` && `brew install ansible`
- {on linux} Manually install Terraform and Ansible before continuing
- Create an SSH keypair in AWS CLI (IAM) and download .pem file
- Copy `{keypair}.pem` file to `~/.ssh` and `chmod 0600 {keypair}.pem`
- Execute `ssh-add {keypair}.pem`
- Copy `terraform/aws.tf.template` to `./aws.tf`
- Run `terraform apply` to create the nodes on AWS
- Run `bash ./configure-networking.sh` to automatically retrieve the IP configuration for your nodes.
- Run `bash ./configure-dcos.sh` to configure Ansible with your desired DC/OS configuration. You will be prompted for several entries.
- Run `ansible-playbook install.yml` to apply the Ansible playbook

## Steps for installation (manual - not using configure-networking.sh and configure-dcos.sh)

- Copy `./ansible.cfg.example` to `./ansible.cfg`

- Add the line `ssh_args = -i ~/.ssh/{keypair}.pem` to the file `./ansible.cfg` to specify the ssh key for Ansible

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
system_updates: false

# Configuration for the Exhibitor Storage Backend
# options: aws_s3, zookeeper, shared_filesystem, static
exhibitor: static

# AWS S3 Credentials (only needed for exhibitor: aws_s3)
aws_access_key_id: "******"
aws_secret_access_key: "******"
aws_region: us-west-2
s3_bucket: bucket-name
s3_prefix: s3-website

# This parameter specifies your desired security mode. (only for Mesosphere Enterprise DC/OS)
# options: disabled, permissive, strict
security: permissive

# Configure rexray to enable support of external volumes (only for Mesosphere Enterprise DC/OS)
# Note: Set rexray_config_method: file and edit ./roles/workstation/templates/rexray.yaml.j2 for a custom rexray configuration
# options: empty, file
rexray_config_method: empty

# Enterprise or OSS?
enterprise_dcos: true

# Customer Key (only for Mesosphere Enterprise DC/OS)
customer_key: "########-####-####-####-############"

# DC/OS credentials (only for Mesosphere Enterprise DC/OS)
superuser_username: admin
superuser_password_hash: "$6$rounds=656000$8CXbMqwuglDt3Yai$ZkLEj8zS.GmPGWt.dhwAv0.XsjYXwVHuS9aHh3DMcfGaz45OpGxC5oQPXUUpFLMkqlXCfhXMloIzE0Xh8VwHJ." # Password: admin
```

- Run `ansible-playbook install.yml`

## Steps for uninstallation

This uninstall playbook runs a cleanup script on the nodes.

- Run `ansible-playbook uninstall.yml`

If you created the AWS environment with the Terraform script you can delete the AWS stack by running the command below.

- Run `terraform destroy`
