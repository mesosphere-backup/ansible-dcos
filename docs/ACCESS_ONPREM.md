## Steps for enable SSH access on nodes with Ansible

Require an [installed ansible package](http://docs.ansible.com/ansible/latest/intro_installation.html) and generated ssh key pair on the ansible control machine:

```
ssh-keygen -t rsa -b 4096 -C "admin@example.com" -f ~/.ssh/ansible-dcos
ssh-add ~/.ssh/ansible-dcos
```

Add the following lines to your `group_vars/all` and be sure all `bootstraps`, `masters`, `agents` and `agent_publics` nodes use the same initial user and password:

```
# For initial SSH access on nodes with Ansible
ansible_password: "YOUR_PASSWORD"
ansible_become_pass: "YOUR_PASSWORD"
#initial_remote_user: root
```

Finally, you can enable access via ssh to all nodes for use with ansible by applying the Ansible playbook:

```
ansible-playbook plays/access-onprem.yml
```
