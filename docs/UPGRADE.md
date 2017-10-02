# Upgrade DC/OS

In order to upgrade a cluster, you have to set the download URL for the target version of DC/OS inside of the file `group_vars/all`. So for example if you want to upgrade to DC/OS 1.9.0, specify the download URL for this version like this:

```
dcos_download: https://downloads.dcos.io/dcos/stable/commit/0ce03387884523f02624d3fb56c7fbe2e06e181b/dcos_generate_config.sh
```

To start the upgrade trigger the play `plays/upgrade.yml` and specify the DC/OS version that is currently running on the cluster as the variable `installed_cluster_version`. The command for that is:

```
ansible-playbook plays/upgrade.yml --extra-vars "installed_cluster_version=1.8.8"
```
