# dcos-onprem-ansible

This ansible playbook installs DC/OS and should run on CentOS/RHEL 7. The installation steps are based on the [Advanced Installation Guide](https://dcos.io/docs/1.7/administration/installing/custom/advanced/) of DC/OS.

## Steps for installation

- Copy `host.example` to `hosts` and fill in the (public) IP addresses of your cluster. For example:

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

...

```

- Copy `group_vars/all.example` to `group_vars/all` and fill in the variables that match your preferred configuration. The variables are explained below.

```
# (internal) IP Address of the Workstation
workstation_ip: 1.0.0.1

# (internal) IP Addresses for the Master Nodes
master_list: |
  - 1.0.0.2

# DNS Resolvers
resolvers: |
  - 172.31.0.2
  - 8.8.8.8

# DNS Search Domain
dns_search: eu-central-1.compute.internal

# SSH User for Installation
remote_user: centos

# Choose the IP Detect Script
# options: default, aws
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

# DC/OS credentials (only needed for Mesosphere Enterprise DC/OS)
superuser_username: admin
superuser_password_hash: ******
```

- Run `ansible-playbook install.yml`

## Steps for uninstallation

This uninstall playbook runs a cleanup script on the nodes.

- Run `ansible-playbook uninstall.yml`
