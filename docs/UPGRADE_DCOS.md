# Steps for DC/OS upgrade On-Premises and on Cloud Providers

In order to upgrade a cluster, you have to set the download URL for the target version of DC/OS inside of the file `group_vars/all/vars`. So for example if you want to upgrade to DC/OS 1.11.1, specify the version within the variable `dcos_version`.

```shell
$ dcos_version: '1.11.1'
```

You also need to specify the DC/OS version that is currently running on the cluster within the variable `dcos_upgrade_from_version`:

```shell
$ dcos_upgrade_from_version: '1.11.0'
```

## On-Premises upgrade

To start the upgrade trigger the play `plays/upgrade.yml`. The command for that is:

```shell
$ ansible-playbook plays/upgrade.yml
```

## Cloud Providers upgrade

To start the upgrade trigger the play `plays/upgrade.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/upgrade.yml
```
