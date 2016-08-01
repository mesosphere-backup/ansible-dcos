# ansible-dcos

This ansible playbook installs DC/OS and should run on CentOS/RHEL 7. The installation steps are based on the [Advanced Installation Guide](https://dcos.io/docs/latest/administration/installing/custom/advanced/) of DC/OS.

## (Optional) Create CentOS machines in AWS

This repo includes the Terraform script `terraform/aws.tf` to create the CentOS machines to run the Ansible script on. This script is just for testing purposes and you don't have to use it.

- Copy `terraform/aws.tf` to `./aws.tf`
- Run `terraform apply` to create the nodes on AWS

There is also the script `setup-ansible.sh` that reads out the IPs from the machines created on AWS and creates the Ansible configuration files `group_vars/all/networking` and `hosts` by using the `.example` files as a template.

- Run `bash ./setup-ansible.sh` to overwrite the Ansible configuration files.

## Steps for installation

- Copy `host.example` to `hosts` and fill in the (public) IP addresses of your cluster. If you followed the steps above this is already done. For example:

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
cluster_name: dcos-ansible

# Choose the IP Detect Script
# options: eth0, eth1, aws, gce
provider: aws

# Download URL for DC/OS
dcos_download: https://downloads.dcos.io/dcos/EarlyAccess/dcos_generate_config.sh

# Configuration for the Exhibitor Storage Backend
# options: aws_s3, zookeeper, shared_filesystem, static
exhibitor: static

# AWS S3 Credentials (only needed for exhibitor: aws_s3)
aws_access_key_id: ******
aws_secret_access_key: ******
aws_region: us-west-2
s3_bucket: janr-bucket
s3_prefix: s3-website

# Configure rexray to enable support of external volumes (only for Mesosphere Enterprise DC/OS)
# options: empty, file
rexray_config_method: empty

# DC/OS credentials (only for Mesosphere Enterprise DC/OS)
superuser_username: admin
superuser_password_hash: ******
```

- Run `ansible-playbook install.yml`

## Steps for uninstallation

This uninstall playbook runs a cleanup script on the nodes.

- Run `ansible-playbook uninstall.yml`

If you created the AWS environment with the Terraform script you can delete the AWS stack by running the command below.

- Run `terraform destroy`
