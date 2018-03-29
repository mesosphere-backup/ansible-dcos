## Steps for enable SSH access on nodes with Ansible

Require an [installed ansible package](http://docs.ansible.com/ansible/latest/intro_installation.html) and generated ssh key pair on the ansible control machine:

```
ssh-keygen -t rsa -b 4096 -C "admin@example.com" -f ~/.ssh/ansible-dcos
ssh-add ~/.ssh/ansible-dcos
```

Add the following lines to your `group_vars/all/vars` and be sure all `bootstraps`, `masters`, `agents` and `public_agents` nodes use the same initial user and password. Also ensure to provide the needed vault variables (you can delete the following lines and the `group_vars/all/vault` after sucessfully applying the Ansible playbook):

```
# For initial SSH access on nodes with Ansible
ansible_password: "{{ vault_ansible_pass }}"
ansible_become_pass: "{{ vault_ansible_pass }}"
#initial_remote_user: root
```

Finally, you can enable access via ssh to all nodes for use with ansible by applying the Absible playbook:

```
ansible-playbook plays/access-onprem.yml
```