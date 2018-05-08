# Steps for DC/OS installation with Ansible On-Premises

With the following guide, you are able to install a DC/OS cluster on premises. You need the Ansible tool installed.
On MacOS, you can use [brew](https://brew.sh/) for that.

```shell
$ brew install ansible
```

## Setup infrastructure

Copy `./hosts.example.yaml` to `./hosts.yaml` and fill in the public IP addresses of your cluster so that Ansible can reach them and additionally set for the variables `dcos_bootstrap_ip` and `dcos_master_list` the private/internal IP addresses for cluster-internal communication. For example:

```
---
# Example for an ansible inventory file
all:
  children:
    bootstraps:
      hosts:
        # Public IP Address of the Bootstrap Node
        1.0.0.1:
    masters:
      hosts:
        # Public IP Addresses for the Master Nodes
        1.0.0.2:
    agents:
      hosts:
        # Public IP Addresses for the Agent Nodes
        1.0.0.3:
        1.0.0.4:
    agent_publics:
      hosts:
        # Public IP Addresses for the Public Agent Nodes
        1.0.0.5:
  vars:
    # IaaS target for DC/OS deployment
    # options: aws, gcp, azure or onprem
    dcos_iaas_target: 'onprem'

    # Choose the IP Detect Script
    # options: eth0, eth1, ... (or other device name for existing network interface)
    dcos_ip_detect_interface: 'eth0'

    # (internal/private) IP Address of the Bootstrap Node
    dcos_bootstrap_ip: '2.0.0.1'

    # (internal/private) IP Addresses for the Master Nodes
    dcos_master_list:
      - 2.0.0.2

    # DNS Resolvers
    dcos_resolvers:
      - 8.8.4.4
      - 8.8.8.8

    # DNS Search Domain
    dcos_dns_search: 'None'

    # Internal Loadbalancer DNS for Masters (only needed for exhibitor: aws_s3)
    dcos_exhibitor_address: 'masterlb.internal'

    # External Loadbalancer DNS for Masters or
    # (external/public) Master Node IP Address (only needed for cli setup)
    dcos_master_address: 'masterlb.external'
```

The setup variables for DC/OS are defined in the file `group_vars/all/vars`. Copy the example files, by running:

```shell
$ cp group_vars/all.example group_vars/all
```

The now created file `group_vars/all` is for configuring DC/OS and common variables. The variables are explained within the files.

### Configure your ssh Keys

Applying the Ansible playbook `ansible-playbook plays/access-onprem.yml` ([see doc](ACCESS_ONPREM.md)) to be able to access your cluster nodes via SSH.

## Install DC/OS

To check that all instances are reachable via Ansible, run the following:

```shell
$ ansible all -m ping
```

Finally, you can install DC/OS by applying the Absible playbook:

```shell
$ ansible-playbook plays/install.yml
```
