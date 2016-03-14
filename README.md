# dcos-onprem-ansible

- Installs DCOS 1.6 EE (w/Authentication)
- Tested with Centos 7

## Steps for installation

1. Copy host.example to hosts and fill in the IP addresses of your cluster

2. Copy group_vars/all.example to group_vars/all and fill in the variables

3. ansible-playbook install.yml

## Steps for uninstallation

1. ansible-playbook uninstall.yml
