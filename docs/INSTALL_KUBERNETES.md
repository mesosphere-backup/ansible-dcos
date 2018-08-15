# Kubernetes on DC/OS as-a-Service On-Premises and on Cloud Providers

Kubernetes is now available as a DC/OS package to quickly, and reliably run Kubernetes clusters on Mesosphere DC/OS.

## Known limitations

Before proceeding, please check the [current Kubernetes package limitations](https://docs.mesosphere.com/service-docs/kubernetes/1.2.1-1.10.6/limitations/).

## Pre-Requisites

Make sure your cluster fulfils the [Kubernetes package default requirements](https://docs.mesosphere.com/service-docs/kubernetes/1.2.1-1.10.6/install/#prerequisites/).

## Install Kubernetes on DC/OS package

### On-Premises installation

To start the package installation trigger the play `plays/kubernetes.yml`. The command for that is:

```shell
$ ansible-playbook plays/kubernetes.yml
```

### Cloud Providers installation

To start the package installation trigger the play `plays/kubernetes.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/kubernetes.yml
```

### Verify installation process

The Kubernetes package installation will take place.

You can watch the progress what was deployed manually with:

```shell
$ watch ./dcos kubernetes plan status deploy
```

Below is an example of how it looks like when the install ran successfully:

```
deploy (serial strategy) (COMPLETE)
├─ etcd (serial strategy) (COMPLETE)
│  ├─ etcd-0:[peer] (COMPLETE)
│  ├─ etcd-1:[peer] (COMPLETE)
│  └─ etcd-2:[peer] (COMPLETE)
├─ apiserver (dependency strategy) (COMPLETE)
│  ├─ kube-apiserver-0:[instance] (COMPLETE)
│  ├─ kube-apiserver-1:[instance] (COMPLETE)
│  └─ kube-apiserver-2:[instance] (COMPLETE)
├─ mandatory-addons (serial strategy) (COMPLETE)
│  ├─ mandatory-addons-0:[additional-cluster-role-bindings] (COMPLETE)
│  ├─ mandatory-addons-0:[kubelet-tls-bootstrapping] (COMPLETE)
│  ├─ mandatory-addons-0:[kube-dns] (COMPLETE)
│  ├─ mandatory-addons-0:[metrics-server] (COMPLETE)
│  ├─ mandatory-addons-0:[dashboard] (COMPLETE)
│  └─ mandatory-addons-0:[ark] (COMPLETE)
├─ kubernetes-api-proxy (dependency strategy) (COMPLETE)
│  └─ kubernetes-api-proxy-0:[install] (COMPLETE)
├─ controller-manager (dependency strategy) (COMPLETE)
│  ├─ kube-controller-manager-0:[instance] (COMPLETE)
│  ├─ kube-controller-manager-1:[instance] (COMPLETE)
│  └─ kube-controller-manager-2:[instance] (COMPLETE)
├─ scheduler (dependency strategy) (COMPLETE)
│  ├─ kube-scheduler-0:[instance] (COMPLETE)
│  ├─ kube-scheduler-1:[instance] (COMPLETE)
│  └─ kube-scheduler-2:[instance] (COMPLETE)
├─ node (dependency strategy) (COMPLETE)
│  ├─ kube-node-0:[kube-proxy, coredns, kubelet] (COMPLETE)
│  ├─ kube-node-1:[kube-proxy, coredns, kubelet] (COMPLETE)
│  └─ kube-node-2:[kube-proxy, coredns, kubelet] (COMPLETE)
└─ public-node (dependency strategy) (COMPLETE)
   └─ kube-node-public-0:[kube-proxy, coredns, kubelet] (COMPLETE)
```

After that, all kubernetes tasks are running and the `kubectl` is configured to access the Kubernetes API from outside the DC/OS cluster.

### Accessing the Kubernetes API

Let's test accessing the Kubernetes API and list the Kubernetes cluster nodes:

```shell
$ ./kubectl get nodes
NAME                                          STATUS    ROLES     AGE       VERSION
kube-node-0-kubelet.kubernetes.mesos          Ready     <none>    3m        v1.10.5
kube-node-1-kubelet.kubernetes.mesos          Ready     <none>    3m        v1.10.5
kube-node-2-kubelet.kubernetes.mesos          Ready     <none>    3m        v1.10.5
kube-node-public-0-kubelet.kubernetes.mesos   Ready     <none>    1m        v1.10.5
```

## Upgrade Kubernetes on DC/OS package

In order to upgrade Kubernetes on DC/OS package, you have to set the target package version of Kubernetes on DC/OS inside of the file `plays/kubernetes.yml`. So for example if you want to upgrade to Kubernetes on DC/OS `1.2.1-1.10.6`, specify the version within the variable `dcos_k8s_package_version`.

```yaml
roles:
  - role: package/kubernetes
    vars:
      dcos_k8s_enabled: true
      dcos_k8s_app_id: 'kubernetes'
      dcos_k8s_package_version: '1.2.1-1.10.6'
```

### On-Premises upgrade

To start the package upgrade trigger the play `plays/kubernetes.yml`. The command for that is:

```shell
$ ansible-playbook plays/kubernetes.yml
```

### Cloud Providers upgrade

To start the package upgrade trigger the play `plays/kubernetes.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/kubernetes.yml
```

For more details, please check the official [Kubernetes package upgrade doc](https://docs.mesosphere.com/services/kubernetes/1.2.1-1.10.6/upgrade/#updating-the-package-version).

## Uninstall Kubernetes on DC/OS package

In order to uninstall Kubernetes on DC/OS, you have to disable the package by changing the variable `dcos_k8s_enabled` to `false` inside of the file `plays/kubernetes.yml`. For example:

```yaml
roles:
  - role: package/kubernetes
    vars:
      dcos_k8s_enabled: false
      dcos_k8s_app_id: 'kubernetes'
      dcos_k8s_package_version: '1.2.1-1.10.6'
```

### On-Premises uninstallation

To start the package uninstallation trigger the play `plays/kubernetes.yml`. The command for that is:

```shell
$ ansible-playbook plays/kubernetes.yml
```

### Cloud Providers uninstallation

To start the package uninstallation trigger the play `plays/kubernetes.yml`. The command for that is:

```shell
$ ansible-playbook -i inventory.py plays/kubernetes.yml
```

## Documentation

For more details, please check the official [Kubernetes package docs](https://docs.mesosphere.com/service-docs/kubernetes/1.2.1-1.10.6).
