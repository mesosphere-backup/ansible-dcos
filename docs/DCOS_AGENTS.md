# Steps to add/remove DC/OS agents On-Premises and on Cloud Providers

## On-Premises

Edit `./hosts.yaml` and fill in the public IP addresses of your cluster agents so that Ansible can reach them:

```
...
    agents:
      hosts:
        # Public IP Addresses for the Agent Nodes
        1.0.0.3:
        1.0.0.4:
    agent_publics:
      hosts:
        # Public IP Addresses for the Public Agent Nodes
        1.0.0.5:
...
```

To check that all instances are reachable via Ansible, run the following:

```shell
$ ansible all -m ping
```

Finally, apply the Ansible playbook:

```shell
$ ansible-playbook plays/install.yml
```

## Cloud Providers

Edit file `.deploy/desired_cluster_profile` with required agents count:

```
num_of_private_agents = "3"
num_of_public_agents = "1"
```

Then you can apply the profile with:

```shell
$ make launch-infra
$ ansible-playbook -i inventory.py plays/install.yml
```
