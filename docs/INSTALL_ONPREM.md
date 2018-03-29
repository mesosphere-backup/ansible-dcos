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

The setup variables for DC/OS are defined in the file `group_vars/all/vars` and `host_vars/localhost/vars`. Copy the example files, by running:

```shell
$ cp group_vars/all/vars.example group_vars/all/vars
cp host_vars/localhost/vars.example host_vars/localhost/vars
```

The now created file `group_vars/all/vars` is for configuring DC/OS and the file `host_vars/localhost/vars` is for configuring common localhost variables. The variables are explained within the files.

Additionally provide the needed vault variables in `host_vars/localhost/vault` for the ansible control machine running all further Ansible scripts like installing command line interfaces (`dcos` & `kubectl`) and [`Kubernetes as-a-Service` (doc)](docs/INSTALL_KUBERNETES.md). 

For installing `Kubernetes as-a-Service` at the end of the DC/OS installation process you need to change the variable `dcos_k8s_enabled`:

```
dcos_k8s_enabled: true
```

### Configure your ssh Keys

Applying the Ansible playbook `ansible-playbook plays/access-onprem.yml` ([see doc](docs/ACCESS_ONPREM.md)) to be able to access your cluster nodes via SSH.

## Install DC/OS

To check that all instances are reachable via Ansible, run the following:

```shell
$ ansible all -m ping
```

Finally, you can install DC/OS by applying the Absible playbook:

```shell
$ ansible-playbook plays/install.yml
```
