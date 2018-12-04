# Testing Mesosphere DC/OS Ansible Roles

Our Ansible roles are accompanied by [molecule](https://molecule.readthedocs.io/en/latest/index.html) test cases.
Both local tests with Vagrant/Virtualbox as well as EC2 instances are used. There are *some* role specific cases in their roles respective `molecule/` director and **a global suite that runs all roles from a single unified playbook by installing full clusers**.

## Example

```bash
# pyenv to 3.6
pip install -r test_requirements.txt
cp group_vars/all/dcos.yaml.example group_vars/all/dcos.yaml
molecule test --scenario-name ec2_centos7
```

## Testing Matrix

Generally this project tries to strictly test the Ansible roles functionality, not features or behaviour of DC/OS itself. As a rule of thumb: If a roles main.yml tasks successfuly execute (e.g. no errors), its considered 'good'.

### i. OS

CentOS current stable plus its EL variant (as per [Mesosphere version policy](https://docs.mesosphere.com/version-policy/)). Depending on upstream OS release cycles, also upcoming versions as part of (beta) testing.

### ii. Infrastrucuture / Provider

* AWS
* Vagrant/Virtualbox

### iii. DC/OS version

Following the [Mesosphere version policy](https://docs.mesosphere.com/version-policy/): 1.12, 1.11, 1.10 currently. Depending on release cycles, also the current beta version.

### iv. DC/OS live cycle

* ivA. the initial install
* ivB. upgrading of a clusters (all node types) and same-version-config-updates
* ivC. running against an up-to-date cluster with no changes expected, this is covered by molecules build-in idempotency checks
