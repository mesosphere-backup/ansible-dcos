# Testing Mesosphere DC/OS Ansible Roles

Our Ansible roles are accompanied by [molecule](https://molecule.readthedocs.io/en/latest/index.html) test cases.
Both local tests with Vagrant/Virtualbox as well as EC2 instances are used. There are *some* role specific cases in their roles respective `molecule/` director and **a global suite that runs all roles from a single unified playbook by installing full clusers**.

## Example
```
# pyenv to 3.6
pip install -r test_requirements.txt
cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml
molecule test --scenario-name ec2_centos7
```
