# Steps for DC/OS installation with Terraform and Ansible on Azure

With the following guide, you are able to install a DC/OS cluster on Azure. You need the tools Terraform and Ansible installed. On MacOS, you can use [brew](https://brew.sh/) for that.

```
brew install terraform
brew install ansible
```

## Setup infrastructure

### Pull down the DC/OS Terraform scripts below

```bash
make azure
```

### Configure your Azure ssh Keys

Set the private key that you will be you will be using to your ssh-agent and set public key in terraform.

```bash
ssh-add ~/.ssh/your_private_azure_key.pem
```

Add your Azure ssh key to `desired_cluster_profile` file:
```
ssh_pub_key = "INSERT_AZURE_PUBLIC_KEY_HERE"
```

### Configure your Azure ID Keys

Follow the Terraform instructions [here](https://www.terraform.io/docs/providers/azurerm/#creating-credentials) to setup your Azure credentials to provide to terraform.

When you've successfully retrieved your output of `az account list`, create a source file to easily run your credentials in the future.


```bash
$ cat ~/.azure/credentials
export ARM_TENANT_ID=45ef06c1-a57b-40d5-967f-88cf8example
export ARM_CLIENT_SECRET=Lqw0kyzWXyEjfha9hfhs8dhasjpJUIGQhNFExAmPLE
export ARM_CLIENT_ID=80f99c3a-cd7d-4931-9405-8b614example
export ARM_SUBSCRIPTION_ID=846d9e22-a320-488c-92d5-41112example
```

### Source Credentials

Set your environment variables by sourcing the files before you run any terraform commands.

```bash
$ source ~/.azure/credentials
```

### Terraform deployment

The setup variables for Terraform are defined in the file `desired_cluster_profile`. You can make a change to the file and it will persist when you do other commands to your cluster in the future.

For example, you can see the default configuration of your cluster:

```bash
$ cat desired_cluster_profile
os = "centos_7.3"
state = "none"
#
num_of_masters = "1"
num_of_private_agents = "3"
num_of_public_agents = "1"
#
azure_region = "East US 2"
azure_bootstrap_instance_type = "Standard_DS1_v2"
azure_master_instance_type = "Standard_D4_v2"
azure_agent_instance_type = "Standard_D4_v2"
azure_public_agent_instance_type = "Standard_D4_v2"
# Inbound Master Access
admin_cidr = "0.0.0.0/0"
```

You can plan the profile with Terraform while referencing:

```bash
make plan
```

If you are happy with the changes, the you can apply the profile with Terraform while referencing:

```bash
make launch-infra
```

## Install DC/OS

Once the components are created, we can run the Ansible script to install DC/OS on the instances.

You have to add the private SSH key (defined in Terraform with variable `ssh_key_name`) to access the instances. Copy the `YOURKEYNAME.pem` file to `~/.ssh` and `chmod 0600 YOURKEYNAME.pem`. After that execute `ssh-add YOURKEYNAME.pem`.

The setup variables for DC/OS are defined in the file `group_vars/all`. Copy the example file, by running:

```
cp group_vars/all.example group_vars/all
```

The now created file `group_vars/all` is for configuring DC/OS. The variables are explained within the file. In order to setup DC/OS for Azure, you should change at least the following variables:

Change the exhibitor backend to `azure`. So the master discovery is done by using an Azure shared storage:

```
# Configuration for the Exhibitor Storage Backend
# options: static, aws_s3, azure
exhibitor: azure
```
You also have to fill Azure Storage Account Name, secret key, blob prefix and container:

```
# Azure Credentials (only needed for exhibitor: azure)
exhibitor_azure_account_name: "******"
exhibitor_azure_account_key: "******"
```

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
make ui
```

The terraform script also created a load balancer for the public agents:

```
make public-lb
```

## Destroy the cluster

To delete the Azure stack run the command:

```
make destroy
```
