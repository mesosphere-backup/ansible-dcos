# Steps for DC/OS installation with Terraform/Ansible on AWS

With the following guide, you are able to install a DC/OS cluster on AWS. You need the tools Terraform and Ansible installed. On MacOS, you can use [brew](https://brew.sh/) for that.

```
brew install terraform
brew install ansible
```

## Setup infrastructure

Start by coping the AWS example template to the root directory:

```
cp terraform/aws.cluster.tf ./cluster.tf`
```

You can now edit the variables inside of the file `cluster.tf` to change the configuration of the machines.

In the following are some variables listed for that you should change the `default` values.

Define a prefix name for your cluster that is unique. So you are able to start more than one DC/OS cluster inside of your AWS account:

```
variable "prefix" {
  description = "Used for naming instances in AWS (e.g. my-dcos)"
  default = "ansible-dcos-01"
}
```

Put in your AWS credentials in order that Terraform is able to access the AWS APIs:

```
variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  default = "YOUR_AWS_ACCESS_KEY_ID"
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  default = "YOUR_AWS_SECRET_ACCESS_KEY"
}
```

Define the name of SSH Key to access the created machines.

```
variable "ssh_key_name" {
  description = "Name of existing AWS key pair to use (e.g. default)"
  default = "YOURKEYNAME"
}
```

You can also restrict the access to various DC/OS HTTP endpoints by defining an IP range for example from your office.

```
variable "admin_ip" {
  description = "Restrict access to the cluster with an IP range (e.g. 1.2.3.4/32)"
  default = ["0.0.0.0/0"]
}
```

The first thing to run is the Terraform script to deploy the cluster components:

```
terraform init
terraform get
terraform apply
```

## Setup Ansible

Once the components are created, we can run the Ansible script to install DC/OS on the instances.

You have to add the private SSH key (defined in Terraform with variable `ssh_key_name`) to access the instances. Copy the `YOURKEYNAME.pem` file to `~/.ssh` and `chmod 0600 YOURKEYNAME.pem`. After that execute `ssh-add YOURKEYNAME.pem`.

The variables for Ansible are defined in the folder `group_vars/all`. Copy over the example directory, by running:

```
cp -R group_vars/all.example/ group_vars/all/
```

The now created file `group_vars/all/setup.yaml` is for configuring DC/OS. You can also run the wizard `bash ./configure-dcos.sh` to create this file and match your preferred configuration. The variables are explained within the file. In order to setup DC/OS for AWS, you should change at the following variables:

Change the exhibitor backend to `aws_s3`. So the master discovery is done by using an S3 bucket:

```
# Configuration for the Exhibitor Storage Backend
# options: aws_s3, static
exhibitor: aws_s3
```
You also have to create an S3 bucket on your own and specify the AWS credentials, the bucket name, and the bucket region:

```
# AWS S3 Credentials (only needed for exhibitor: aws_s3)
aws_access_key_id: "YOUR_AWS_ACCESS_KEY_ID"
aws_secret_access_key: "YOUR_AWS_SECRET_ACCESS_KEY"
aws_region: YOUR_BUCKET_REGION
s3_bucket: YOUR_BUCKET_NAME
```

Ansible also needs to know how to find the instances that got created via Terraform. For that run the following:

```
bash prepare-ansible.sh
```

Now check that all instances are reachable via Ansible:

```
ansible all -m ping
```

Finally, you can install DC/OS by running:

```
ansible-playbook install.yml
```

## Access the cluster

If the installation was successful. You should be able to reach the Master load balancer. You can find the URL of the Master LB with the following command:

```
terraform output lb_external_masters
```

The terraform script also created a load balancer for the public agents:

```
terraform output lb_external_agents
```

## Destroy the cluster

To delete the AWS stack run the command:

```
terraform destroy
```
