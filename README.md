# Deploy DC/OS using Ansible

## Overview

Infrastructure for Cloud Providers is bootstrapped with Terraform.

Ansible playbook installs Open or Enterprise DC/OS to infrastucture On-Premises/Cloud Providers and is supposed to run on CentOS 7.
The installation steps are based on the [Advanced Installation Guide][mesosphere-install] of DC/OS.

## Getting Started

All development is done on the master branch. Tested versions are identified via git tags. To get started, you can clone or fork this repo:

```shell
git clone https://github.com/dcos-labs/ansible-dcos
```

Use `git tag` to list all versions:

```shell
git tag
v0.7.0-dcos-1.11
```

Check out the latest version with:

```shell
git checkout v0.7.0-dcos-1.11
```

## Install

Here are guides to follow to install the DC/OS cluster:

* [On-Premises with Ansible](docs/INSTALL_ONPREM.md)
* [On AWS with Terraform/Ansible](docs/INSTALL_AWS.md)
* [On Azure with Terraform/Ansible](docs/INSTALL_AZURE.md)
* [On GCP with Terraform/Ansible](docs/INSTALL_GCP.md)

Here are guides to follow to install `framework as-a-service`:

* [Kubernetes as-a-Service](docs/INSTALL_KUBERNETES.md)

## Operational tasks

Upgrade the DC/OS cluster:

* [Upgrade DC/OS](docs/UPGRADE_DCOS.md)

Change number of DC/OS agents:

* [Add/remove DC/OS agents](docs/DCOS_AGENTS.md)

Upgrade the Kubernetes cluster:

* [Upgrade Kubernetes as-a-Service](docs/INSTALL_KUBERNETES.md#upgrade-kubernetes-on-dcos-package)

## Documentation

All documentation for this project is located in the [docs](docs/) directory at the root of this repository.

## Acknowledgements

Current maintainers:

* [Jan Repnak][github-jrx]
* [Rimas Mocevicius][github-rimusz]

## Roadmap

  - [X] Support for On-Premises
  - [X] Support for AWS
  - [X] Support for Azure
  - [X] Support for GCP
  - [X] Support Kubernetes as-a-service

## License
[DC/OS][github-dcos], along with this project, are both open source software released under the
[Apache Software License, Version 2.0](LICENSE).

[mesosphere-install]: https://docs.mesosphere.com/latest/installing/ent/custom/advanced/
[github-dcos]: https://github.com/dcos/dcos
[github-jrx]: https://github.com/jrx
[github-rimusz]: https://github.com/rimusz
