# ansible-dcos

This ansible playbook installs DC/OS and is supposed to run on CentOS 7. The installation steps are based on the [Advanced Installation Guide](https://docs.mesosphere.com/latest/administration/installing/custom/advanced/) of DC/OS.

## Steps for installation

- Clone or fork this repo: `git clone https://github.com/mesosphere/ansible-dcos`

- (on a MacOS) `brew install terraform` && `brew install ansible`

- (on Linux) Manually install Terraform and Ansible before continuing

- Create an SSH keypair in AWS CLI (IAM) and download .pem file

- Copy `{keypair}.pem` file to `~/.ssh` and `chmod 0600 {keypair}.pem`

- Execute `ssh-add {keypair}.pem`

- Create the ansible configuration file: `cp ./ansible.cfg.example ./ansible.cfg`

- Create the `group_vars/all` directory from the example: `cp -r group_vars/all.example group_vars/all`

- The file `group_vars/all/setup.yaml` is for configuring DC/OS. You can run the wizard `bash ./configure-dcos.sh` to create this file and match your preferred configuration. The variables are explained within the example below:

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

- Copy the terraform template to root: `cp terraform/aws.example.tf ./aws.tf`

- Run `terraform get` to retrieve the modules

- Run `terraform apply` to create the nodes on AWS

- Run `bash prepare-ansible.sh` to retrieve the IP configuration for your nodes from Terraform

- Run `ansible all -m ping` to check SSH connectivity

- Run `ansible-playbook install.yml` to apply the Ansible playbook

- Run `ansible-playbook configure.yml` to apply additional roles (e.g. Install Marathon-LB, configure LDAP)

## Steps for uninstallation

This uninstall playbook runs a cleanup script on the nodes.

- Run `ansible-playbook uninstall.yml`

You can delete the AWS stack by running the command below.

- Run `terraform destroy`
