# Kubernetes on DC/OS as-a-Service On-Premises and on Cloud Providers

Kubernetes is now available as a DC/OS package to quickly, and reliably run Kubernetes clusters on Mesosphere DC/OS.

## Known limitations

Before proceeding, please check the [current Kubernetes package limitations](https://docs.mesosphere.com/service-docs/kubernetes/1.0.2-1.9.6/limitations/).

## Pre-Requisites

Make sure your cluster fulfils the [Kubernetes package default requirements](https://docs.mesosphere.com/service-docs/kubernetes/1.0.2-1.9.6/install/#prerequisites/).

## Install Kubernetes on DC/OS package

### On-Premises installation

To start the package installation trigger the play `plays/k8s-install.yml`. The command for that is:

```shell
$ ansible-playbook plays/k8s-install.yml
```

### Cloud Providers installation

To start the package installation trigger the play `plays/k8s-install.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/k8s-install.yml
```

### Verify installation process

The Kubernetes package installation will take place.

You can watch the progress what was deployed manuelly with:

```shell
$ watch dcos kubernetes plan status deploy
```

Below is an example of how it looks like when the install ran successfully:

```
deploy (serial strategy) (COMPLETE)
├─ etcd (serial strategy) (COMPLETE)
│  ├─ etcd-0:[peer] (COMPLETE)
│  ├─ etcd-1:[peer] (COMPLETE)
│  └─ etcd-2:[peer] (COMPLETE)
├─ apiserver (parallel strategy) (COMPLETE)
│  ├─ kube-apiserver-0:[instance] (COMPLETE)
│  ├─ kube-apiserver-1:[instance] (COMPLETE)
│  └─ kube-apiserver-2:[instance] (COMPLETE)
├─ kubernetes-api-proxy (parallel strategy) (COMPLETE)
│  └─ kubernetes-api-proxy-0:[install] (COMPLETE)
├─ controller-manager (parallel strategy) (COMPLETE)
│  ├─ kube-controller-manager-0:[instance] (COMPLETE)
│  ├─ kube-controller-manager-1:[instance] (COMPLETE)
│  └─ kube-controller-manager-2:[instance] (COMPLETE)
├─ scheduler (parallel strategy) (COMPLETE)
│  ├─ kube-scheduler-0:[instance] (COMPLETE)
│  ├─ kube-scheduler-1:[instance] (COMPLETE)
│  └─ kube-scheduler-2:[instance] (COMPLETE)
├─ node (parallel strategy) (COMPLETE)
│  ├─ kube-node-0:[kube-proxy] (COMPLETE)
│  ├─ kube-node-0:[coredns] (COMPLETE)
│  ├─ kube-node-0:[kubelet] (COMPLETE)
│  ├─ kube-node-1:[kube-proxy] (COMPLETE)
│  ├─ kube-node-1:[coredns] (COMPLETE)
│  ├─ kube-node-1:[kubelet] (COMPLETE)
│  ├─ kube-node-2:[kube-proxy] (COMPLETE)
│  ├─ kube-node-2:[coredns] (COMPLETE)
│  └─ kube-node-2:[kubelet] (COMPLETE)
├─ public-node (parallel strategy) (COMPLETE)
│  ├─ kube-node-public-0:[kube-proxy] (COMPLETE)
│  ├─ kube-node-public-0:[coredns] (COMPLETE)
│  └─ kube-node-public-0:[kubelet] (COMPLETE)
└─ mandatory-addons (serial strategy) (COMPLETE)
   ├─ mandatory-addons-0:[kube-dns] (COMPLETE)
   ├─ mandatory-addons-0:[metrics-server] (COMPLETE)
   ├─ mandatory-addons-0:[dashboard] (COMPLETE)
   └─ mandatory-addons-0:[ark] (COMPLETE)
```

After that, all kubernetes tasks are running and the `kubectl` is configured to access the Kubernetes API from outside the DC/OS cluster, 
including an established ssh tunnel for running more advanced commands such as `kubectl proxy`.

### Accessing the Kubernetes API

Let's test accessing the Kubernetes API and list the Kubernetes cluster nodes:

```shell
$ kubectl get nodes
NAME                                          STATUS    ROLES     AGE       VERSION
kube-node-0-kubelet.kubernetes.mesos          Ready     <none>    8m        v1.9.6
kube-node-1-kubelet.kubernetes.mesos          Ready     <none>    8m        v1.9.6
kube-node-2-kubelet.kubernetes.mesos          Ready     <none>    8m        v1.9.6
kube-node-public-0-kubelet.kubernetes.mesos   Ready     <none>    7m        v1.9.6
```

## Upgrade Kubernetes on DC/OS package

In order to upgrade Kubernetes on DC/OS package, you have to set the target package version of Kubernetes on DC/OS inside of the file `group_vars/all/vars`. So for example if you want to upgrade to Kubernetes on DC/OS 1.0.2-1.9.6, specify the version within the variable `dcos_k8s_package_version`.

```shell
$ dcos_k8s_package_version: '1.0.2-1.9.6'
```

### On-Premises upgrade

To start the package upgrade trigger the play `plays/k8s-update.yml`. The command for that is:

```shell
$ ansible-playbook plays/k8-update.yml
```

### Cloud Providers upgrade

To start the package upgrade trigger the play `plays/k8s-update.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/k8-update.yml
```

For more details, please check the official [Kubernetes package upgrade doc](https://docs.mesosphere.com/services/kubernetes/1.0.2-1.9.6/upgrade/#updating-the-package-version/).

## Update Kubernetes on DC/OS package options

In order to update Kubernetes on DC/OS package options, you have to edit your current Kubernetes on DC/OS options file `.deploy/kubernetes/options.json`.

### On-Premises update

To start the package options update trigger the play `plays/k8s-update.yml`. The command for that is:

```shell
$ ansible-playbook plays/k8-update.yml
```

### Cloud Providers update

To start the package options update trigger the play `plays/k8s-update.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/k8-update.yml
```

For more details, please check the official [Kubernetes package options update doc](https://docs.mesosphere.com/services/kubernetes/1.0.2-1.9.6/upgrade/#updating-the-package-options/).

## Uninstall Kubernetes on DC/OS package

### On-Premises uninstallation

To start the package uninstallation trigger the play `plays/k8s-uninstall.yml`. The command for that is:

```shell
$ ansible-playbook plays/k8s-uninstall.yml
```

### Cloud Providers uninstallation

To start the package uninstallation trigger the play `plays/k8s-uninstall.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/k8s-uninstall.yml
```

## Documentation

For more details, please check the official [Kubernetes package docs](https://docs.mesosphere.com/service-docs/kubernetes/1.0.2-1.9.6).
