# Steps for DC/OS installation with Terraform and Ansible on GCP

With the following guide, you are able to install a DC/OS cluster on GCP. You need the tools Terraform and Ansible installed. On MacOS, you can use [brew](https://brew.sh/) for that.

```shell
$ brew install terraform
$ brew install ansible
```

## Setup infrastructure

### Prerequisites
- [Terraform 0.11.x](https://www.terraform.io/downloads.html)
- GCP Cloud Credentials. _[configure via: `gcloud auth login`](https://cloud.google.com/sdk/downloads)_
- SSH Key
- Existing Google Project.

### Install Google SDK

Run this command to authenticate to the Google Provider. This will bring down your keys locally on the machine for terraform to use.

```shell
$ gcloud auth login
$ gcloud auth application-default login
```

### Pull down the DC/OS Terraform scripts below

```shell
$ make gcp
```

### Configure your GCP ssh keys

Set the public key that you will be you will be using to your ssh-agent and set public key in terraform. This will allow you to log into to the cluster after DC/OS is deployed and also helps Terraform setup your cluster at deployment time.

```shell
$ ssh-add ~/.ssh/google_compute_engine.pub
```

Add your ssh key to `.deploy/desired_cluster_profile` file:
```
gcp_ssh_pub_key_file = "INSERT_PUBLIC_KEY_PATH_HERE"
```

### Configure a Pre-existing GCP Project

ansible-dcos assumes a project already exist in GCP to start deploying your resources against.

Add your GCP project to `.deploy/desired_cluster_profile` file:
```
gcp_project = "massive-bliss-781"
```

### Terraform deployment

The setup variables for Terraform are defined in the file `.deploy/desired_cluster_profile`. You can make a change to the file and it will persist when you do other commands to your cluster in the future.

For example, you can see the default configuration of your cluster:

```shell
$ cat .deploy/desired_cluster_profile
os = "centos_7.3"
state = "none"
#
num_of_masters = "1"
num_of_private_agents = "3"
num_of_public_agents = "1"
#
gcp_project = "YOUR_GCP_PROJECT"
gcp_region = "us-central1"
gcp_ssh_pub_key_file = "/PATH/YOUR_GCP_SSH_PUBLIC_KEY.pub"
#
# If you want to use GCP service account key instead of GCP SDK
# uncomment the line below and update it with the path to the key file
#gcp_credentials_key_file = "/PATH/YOUR_GCP_SERVICE_ACCOUNT_KEY.json"
#
gcp_bootstrap_instance_type = "n1-standard-1"
gcp_master_instance_type = "n1-standard-8"
gcp_agent_instance_type = "n1-standard-8"
gcp_public_agent_instance_type = "n1-standard-8"
#
# Change public/private subnetworks e.g. "10.65." if you want to run multiple clusters in the same project
gcp_compute_subnetwork_public = "10.64.0.0/22"
gcp_compute_subnetwork_private = "10.64.4.0/22"
# Inbound Master Access
admin_cidr = "0.0.0.0/0"
```

You can plan the profile with Terraform while referencing:

```shell
$ make plan
```

If you are happy with the changes, then you can apply the profile with Terraform while referencing:

```shell
$ make launch-infra
```

## Install DC/OS

Once the components are created, we can run the Ansible script to install DC/OS on the instances.

The setup variables for DC/OS are defined in the file `group_vars/all/vars`. Copy the example files, by running:

```shell
$ cp group_vars/all.example group_vars/all
```

The now created file `group_vars/all` is for configuring DC/OS and common variables. The variables are explained within the files.

Ansible also needs to know how to find the instances that got created via Terraform. For that we run a dynamic inventory script called `./inventory.py`. To use it specify the script with the parameter `-i`. In example, check that all instances are reachable via Ansible:

```shell
$ ansible all -i inventory.py -m ping
```

Finally, you can install DC/OS by running:

```shell
$ ansible-playbook -i inventory.py plays/install.yml
```

## Access the cluster

If the installation was successful. You should be able to reach the Master load balancer. You can find the URL of the Master LB with the following command:

```shell
$ make ui
```

The terraform script also created a load balancer for the public agents:

```shell
$ make public-lb
```

## Destroy the cluster

To delete the GCP stack run the command:

```shell
$ make destroy
```
