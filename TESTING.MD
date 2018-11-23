# Testing Mesosphere DC/OS Ansible Roles

Our Ansible roles are accompanied by [molecule](https://molecule.readthedocs.io/en/latest/index.html) test cases.
Both local tests with Vagrant/Virtualbox as well as EC2 instances are used.

## Example
```
# pyenv to 3.6
pip install -r test_requirements.txt
cd roles/DCOS.requirements/
molecule test
```
