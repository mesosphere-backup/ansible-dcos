# Steps for DC/OS installation with Terraform and Ansible on GCP

With the following guide, you are able to install a DC/OS cluster on GCP. You need the tools Terraform and Ansible installed. On MacOS, you can use [brew](https://brew.sh/) for that.

```
brew install terraform
brew install ansible
```

## Setup infrastructure

### Prerequisites
- [Terraform 0.11.x](https://www.terraform.io/downloads.html)
- GCP Cloud Credentials. _[configure via: `gcloud auth login`](https://cloud.google.com/sdk/downloads)_
- SSH Key
- Existing Google Project.

### Install Google SDK

Run this command to authenticate to the Google Provider. This will bring down your keys locally on the machine for terraform to use.

```bash
$ gcloud auth login
$ gcloud auth application-default login
```

### Pull down the DC/OS Terraform scripts below

```bash
terraform init -from-module github.com/dcos/terraform-dcos//gcp
```

### Terraform variables

Some Terraform variables need to be overwritten, copy the `override.tf` file, by running:
```bash
cp terraform/override.gcp.tf ./override.tf
```

The setup variables for Terraform are defined in the file `desired_cluster_profile`. Copy the example file, by running:
```bash
cp desired_cluster_profile.example desired_cluster_profile
```

### Configure your GCP ssh keys

Set the public key that you will be you will be using to your ssh-agent and set public key in terraform. This will allow you to log into to the cluster after DC/OS is deployed and also helps Terraform setup your cluster at deployment time.

```bash
$ ssh-add ~/.ssh/google_compute_engine.pub
```

Add your ssh key to `desired_cluster_profile` file:
```
gce_ssh_pub_key_file = "INSERT_PUBLIC_KEY_PATH_HERE"
```

### Configure a Pre-existing GCP Project

ansible-dcos assumes a project already exist in GCP to start deploying your resources against.

Add your GCP project to `desired_cluster_profile` file:
```
google_project = "massive-bliss-781"
```

### Example Terraform Deployments

When reading the commands below relating to installing and upgrading, it may be easier for you to keep all these flags in a file instead. This way you can make a change to the file and it will persist when you do other commands to your cluster in the future.

For example, you can see how you can save your state of your cluster in a file called `desired_cluster_profile`:

```bash
$ cat desired_cluster_profile
num_of_masters = "1"
num_of_private_agents = "3"
num_of_public_agents = "1"
os = "centos_7.3"
state = "none"
gce_ssh_pub_key_file = "~/.ssh/google_compute_engine.pub"
google_project = "massive-bliss-781"
```

You can plan the profile with Terraform while referencing:

```bash
terraform plan -var-file desired_cluster_profile
```

If you are happy with the changes, the you can apply the profile with Terraform while referencing:

```bash
terraform apply -var-file desired_cluster_profile
```

## Install DC/OS

Once the components are created, we can run the Ansible script to install DC/OS on the instances.

The setup variables for DC/OS are defined in the file `group_vars/all`. Copy the example file, by running:

```
cp group_vars/all.example group_vars/all
```

The now created file `group_vars/all` is for configuring DC/OS. The variables are explained within the file.

Ansible also needs to know how to find the instances that got created via Terraform.  For that we you run a dynamic inventory script called `./inventory.py`. To use it specify the script with the parameter `-i`. In example, check that all instances are reachable via Ansible:

```
ansible all -i inventory.py -m ping
```

Finally, you can install DC/OS by running:

```
ansible-playbook -i inventory.py plays/install.yml
```

## Access the cluster

If the installation was successful. You should be able to reach the Master load balancer. You can find the URL of the Master LB with the following command:

```
terraform output "Master ELB Address"
```

The terraform script also created a load balancer for the public agents:

```
terraform output "Public Agent ELB Address"
```

## Destroy the cluster

To delete the GCP stack run the command:

```
terraform destroy -var-file desired_cluster_profile
```
