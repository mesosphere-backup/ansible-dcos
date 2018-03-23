# Steps for DC/OS upgrade On-Premises and on Cloud Providers

In order to upgrade a cluster, you have to set the download URL for the target version of DC/OS inside of the file `group_vars/all`. So for example if you want to upgrade to DC/OS 1.11.1, specify the download URL for this version within the variable `dcos_download`.

```shell
$ dcos_download: https://downloads.dcos.io/dcos/stable/1.11.1/dcos_generate_config.sh
```

You also need to specify the DC/OS version that is currently running on the cluster within the variable `dcos_upgrade_from_version`:

```shell
$ dcos_upgrade_from_version: '1.11.0'
```

## On-Premises upgrade

To start the upgrade trigger the play `plays/upgrade.yml` and

```shell
$ ansible-playbook plays/upgrade.yml
```

## Cloud Providers upgrade

To start the upgrade trigger the play `plays/upgrade.yml` and specify the DC/OS version that is currently running on the cluster as the variable `installed_cluster_version`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/upgrade.yml
```
