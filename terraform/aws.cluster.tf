variable "prefix" {
  description = "Used for naming instances in AWS (e.g. my-dcos)"
  default = "ansible-dcos-01"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  default = "YOUR_AWS_ACCESS_KEY_ID"
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  default = "YOUR_AWS_SECRET_ACCESS_KEY"
}

variable "ssh_key_name" {
  description = "Name of existing AWS key pair to use (e.g. default)"
  default = "default"
}

variable "admin_ip" {
  description = "Restrict access to the cluster with an IP range (e.g. 1.2.3.4/32)"
  default = ["0.0.0.0/0"]
}

variable "owner" {
  description = "AWS tag of the owner (e.g. Slack username)"
  default = "username"
}

variable "expiration" {
  description = "AWS tag of the expiration time (e.g. 8hours)"
  default = "8hours"
}

variable "bootstrap_instance_count" {
  description = "Number of bootstrap nodes to launch"
  default = 1
}

variable "master_instance_count" {
  description = "Number of master nodes to launch [1, 3, 5]"
  default = 3
}

variable "agent_instance_count" {
  description = "Number of agent nodes to launch"
  default = 6
}

variable "public_agent_instance_count" {
  description = "Number of public agent nodes to launch"
  default = 1
}

variable "region" {
  default = "us-west-2"
}

# availability zones
# use "aws ec2 describe-availability-zones --region us-east-1"
# to figure out the name of the AZs on every region
variable "azs" {
  default = {
    "eu-central-1" = "eu-central-1a,eu-central-1b"
    "us-west-2" = "us-west-2a,us-west-2b,us-west-2c"
    "us-east-1" = "us-east-1a,us-east-1b,us-east-1c,us-east-1e"
    "eu-west-1" = "eu-west-1a,eu-west-1b,eu-west-1c"
  }
}

variable "azs_master" {
  default = {
    "eu-central-1" = "eu-central-1a"
    "us-west-2" = "us-west-2a"
    "us-east-1" = "us-east-1a"
    "eu-west-1" = "eu-west-1a"
  }
}

variable "amis" {
  default = {
    eu-central-1 = "ami-fa2df395"
    eu-west-1 = "ami-f5d7f195"
    us-west-2 = "ami-f4533694"
    us-east-1 = "ami-46c1b650"
  }
}

variable "bootstrap_type" { default = "m4.large" }
variable "master_type" { default = "m4.2xlarge" }
variable "agent_type" { default = "m4.2xlarge" }
variable "public_agent_type" { default = "m4.xlarge" }
variable "bootstrap_volume_size" { default = "60" }
variable "master_volume_size" { default = "100" }
variable "agent_volume_size" { default = "100" }
variable "public_agent_volume_size" { default = "100" }

variable "subnet_dns" { default = "172.31.0.2" }
variable "subnet_range" { default = "172.31.0.0/16" }

provider "aws" {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region = "${var.region}"
}

module "vpc" {
  source ="./terraform/aws/vpc"
  subnet_range = "${var.subnet_range}"
  azs = "${var.azs}"
  region = "${var.region}"
  prefix = "${var.prefix}"
}

module "iam" {
  source ="./terraform/aws/iam"
  prefix = "${var.prefix}"
}

module "security-groups" {
  source ="./terraform/aws/security-groups"
  prefix = "${var.prefix}"
  admin_ip = "${var.admin_ip}"
  subnet_range = "${var.subnet_range}"
  vpc_id = "${module.vpc.vpc_id}"
}

module "elb" {
  source ="./terraform/aws/elb"
  prefix = "${var.prefix}"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
  subnets = "${module.vpc.subnets}"
  security_groups_internal_masters = ["${module.security-groups.internal_sg}"]
  security_groups_external_masters = ["${module.security-groups.internal_sg}","${module.security-groups.lb_masters_sg}"]
  security_groups_external_agents = ["${module.security-groups.internal_sg}","${module.security-groups.lb_agents_sg}"]
  master_instances = "${module.master.instances}"
  public_agent_instances = "${module.public_agent.instances}"
}

module "bootstrap" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-bootstrap"
  instance_count = "${var.bootstrap_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs_master}"
  region = "${var.region}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnets = "${module.vpc.subnets}"
  iam_instance_profile = ""
  instance_type = "${var.bootstrap_type}"
  volume_size = "${var.bootstrap_volume_size}"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

module "master" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-master"
  instance_count = "${var.master_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs_master}"
  region = "${var.region}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnets = "${module.vpc.subnets}"
  iam_instance_profile = ""
  instance_type = "${var.master_type}"
  volume_size = "${var.master_volume_size}"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

module "agent" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-agent"
  instance_count = "${var.agent_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs}"
  region = "${var.region}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnets = "${module.vpc.subnets}"
  iam_instance_profile = "${module.iam.agent_profile}"
  instance_type = "${var.agent_type}"
  volume_size = "${var.agent_volume_size}"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

module "public_agent" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-public_agent"
  instance_count = "${var.public_agent_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs}"
  region = "${var.region}"
  key_name = "${var.ssh_key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnets = "${module.vpc.subnets}"
  iam_instance_profile = "${module.iam.agent_profile}"
  instance_type = "${var.public_agent_type}"
  volume_size = "${var.public_agent_volume_size}"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

output "lb_external_masters" { value = "${module.elb.external_masters_dns_name}" }
output "lb_internal_masters" { value = "${module.elb.internal_masters_dns_name}" }
output "lb_external_agents" { value = "${module.elb.external_agents_dns_name}" }
output "bootstrap_public_ips" { value = "${module.bootstrap.public_ips}" }
output "bootstrap_private_ips" { value = "${module.bootstrap.private_ips}" }
output "master_public_ips" { value = "${module.master.public_ips}" }
output "master_private_ips" { value = "${module.master.private_ips}" }
output "agent_public_ips" { value = "${module.agent.public_ips}" }
output "public_agent_public_ips" { value = "${module.public_agent.public_ips}" }
output "prefix" { value = "${var.prefix}" }
output "dns" { value = "${var.subnet_dns}" }
output "dns_search" { value = "${var.region}.compute.internal" }

/*resource "null_resource" "cluster" {

  # Changes to any instance of the cluster requires adjusting the ansible configuration
  triggers {
    lb_external_masters = "${module.elb.external_masters_dns_name}"
    lb_internal_masters = "${module.elb.internal_masters_dns_name}"
    lb_external_agents = "${module.elb.external_agents_dns_name}"
    bootstrap_public_ips = "${module.bootstrap.public_ips}"
    bootstrap_private_ips = "${module.bootstrap.private_ips}"
    master_public_ips = "${module.master.public_ips}"
    master_private_ips = "${module.master.private_ips}"
    agent_public_ips = "${module.agent.public_ips}"
    public_agent_public_ips = "${module.public_agent.public_ips}"
    prefix = "${var.prefix}"
    dns = "${var.subnet_dns}"
    dns_search = "${var.region}.compute.internal"
  }

  provisioner "local-exec" {
      command = "sleep 5 && bash prepare-ansible.sh"
  }
}*/
