# Ansible Roles: Mesosphere DC/OS

A set of Ansible Roles that install DC/OS on RedHat/CentOS Linux.

## Requirements

To make best use of these rolens, you nodes should resemble the Mesosphere recommended way of setting up infrastructure. Depending on your setup, it is expected to deploy to:

* One ore more master node ('masters')
* One bootstrap node ('bootstraps')
* Zero or more agent nodes, used for public facing services ('agents_public')
* One or more agent nodes, not used for public facing services ('agents_private')

### An example inventory file is provided as shown here:

```ini
[bootstraps]
bootstrap1-dcos112s.example.com

[masters]
master1-dcos112s.example.com
master2-dcos112s.example.com
master3-dcos112s.example.com

[agents_private]
agent1-dcos112s.example.com
remoteagent1-dcos112s.example.com

[agents_public]
publicagent1-dcos112s.example.com

[agents:children]
agents_private
agents_public

[common:children]
bootstraps
masters
agents
agents_public
```

## Roles Variables

The Mesosphere DC/OS Ansible roles make use of two sets of variables

1. A set of per node type `group_var`'s
2. A multi-level dictory called `dcos`, that should be available to all nodes

### Per group vars

```ini
[bootstraps:vars]
node_type=bootstrap

[masters:vars]
node_type=master
dcos_legacy_node_type_name=master

[agents_private:vars]
node_type=agent
dcos_legacy_node_type_name=slave

[agents_public:vars]
node_type=agent_public
dcos_legacy_node_type_name=slave_public
```

### Global vars

```yml
dcos:
  download: "https://downloads.dcos.io/dcos/EarlyAccess/dcos_generate_config.sh"
  version: "1.12.0-beta1"
  version_to_upgrade_from: "1.12.0-dev"
  enterprise_dcos: false
  selinux_mode: enforcing

  config:
    cluster_name: "examplecluster"
    security: strict
    bootstrap_url: http://int-bootstrap1-examplecluster.example.com:8080
    exhibitor_storage_backend: static
    master_discovery: static
    master_list:
      - 172.31.42.1
```

#### Cluster wide variables

| Name  | Required?  | Description  |
|---|---|---|
| download | REQUIRED  | (https) URL to download the Mesosphere DC/OS install from |
| version | REQUIRED  | Version string that reflects the version that the installer (given by `download`) installs. Can be collected by running `dcos_generate_config.sh --version`. |
| version_to_upgrade_from  | for upgrades  | Version string of Mesosphere DC/OS the upgrade procedure expectes to upgrade FROM. A per-version upgrade script will be generated on the bootstrap machine, each cluster node downloads the proper upgrade for its currenly running DC/OS version.|
| image_commit | no| Can be used to force same version / same config upgrades. Mostly useful for deploying/upgrading non-released versions, e.g. `1.12-dev`. This parameter takes precedence over `version`.|
| enterprise_dcos | REQUIRED | Specifies if the installer (given by `download`) installs an 'open' or 'enterprise' version of Mesosphere DC/OS. This is required as there are additional post-upgrade checks for enterprise-only components.|
| selinux_mode | REQUIRED | Indicates the cluster nodes operating sytems SELinux mode. Mesosphere DC/OS supports running in `enforcing` mode starting with **1.12**. Older versions require `permissive`.|
||||
| config | yes | Yaml structure that represents a valid Mesosphere DC/OS config.yml, see below.|

#### DC/OS config.yml parameters
Please see [the official Mesosphere DC/OS configuration reference](https://docs.mesosphere.com/1.12/installing/production/advanced-configuration/configuration-reference/) for a full list of possible parameters.
There are a few parameters that are used by these roles outside the DC/OS config.yml, namingly:

* `bootstrap_url`: Should point to http://*your bootstrap node*:8080. Will be used internally and conviniently overwritten for the installer/upgrader to point to a version specific sub-directory.

## Example playbook

Mesosphere DC/OS is a complex system, spanning multiple nodes to form a full multi-node cluster. There are some constraints in making a playbook use the provided roles:

1. Order of groups to run their respective roles on (e.g. bootstrap node first, then masters, then agents)
2. Concurrency for upgrades (e.g. `serial: 1` for master nodes)

The provided `dcos.yml` playbook can be used as-is for installing and upgrading Mesosphere DC/OS.

## Tested OS and Mesosphere DC/OS versions

* CentOS 7
* DC/OS 1.12, both open as well as enterprise version

## License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## Author Information
This role was created by team SRE @ Mesosphere and others in 2018, based on multiple internal tools and non-public Ansible roles that have been developed internally over the years.
