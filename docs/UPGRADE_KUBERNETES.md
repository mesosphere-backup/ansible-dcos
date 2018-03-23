# Kubernetes upgrade

## Updating

In order to update the package, the `dcos kubernetes update` subcommand
is available.

```shell
$ dcos kubernetes update -h
usage: dcos kubernetes [<flags>] update [<flags>]

Flags:
  -h, --help               Show context-sensitive help.
  -v, --verbose            Enable extra logging of requests/responses
      --name="kubernetes"  Name of the service instance to query
      --options=OPTIONS    Path to a JSON file containing the target package options
      --package-version=PACKAGE-VERSION
                           The target package version
      --yes                Do not ask for confirmation before starting the update process
      --timeout=1200s      Maximum time to wait for the update process to complete

```

### Updating the package version

Before starting the update process, it is recommended to install the CLI
of the new package version:

```shell
$ dcos package install kubernetes --cli --package-version=<NEW_VERSION>
```

#### Kubernetes on DC/OS Enterprise Edition

Below is how the user starts the package version update:

```shell
$ dcos kubernetes update --package-version=<NEW_VERSION>
About to start an update from version <CURRENT_VERSION> to <NEW_VERSION>

Updating these components means the Kubernetes cluster may experience some
downtime or, in the worst-case scenario, cease to function properly.
Before updating proceed cautiously and always backup your data.

This operation is long-running and has to run to completion.
Are you sure you want to continue? [yes/no] yes

2018/03/01 15:40:14 starting update process...
2018/03/01 15:40:15 waiting for update to finish...
2018/03/01 15:41:56 update complete!
```

#### Kubernetes on DC/OS Open Edition

In contrast to the Enterprise edition, the package upgrade requires some additional
steps to achieve the same result.

First, export the current package configuration into a JSON file called `config.json`:

```shell
$ dcos kubernetes describe > config.json
```

In order to upgrade in a non-destructive manner, first remove the DC/OS Kubernetes
scheduler by running:

```shell
$ dcos marathon app remove /kubernetes
```

And then install the new version of the package:

```shell
$ dcos package install kubernetes --package-version=<NEW_VERSION> --options=config.json
```

You can watch the upgrade progress with:

```shell
$ watch dcos kubernetes plan show deploy
```

## Documentation

For more details, please check the official [Kubernetes package upgrade doc](https://docs.mesosphere.com/services/kubernetes/1.0.2-1.9.6/upgrade/#updating-the-package-version/).
