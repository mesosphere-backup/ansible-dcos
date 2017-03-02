# define instance count for each node type

variable "workstation_instance_count" {
  description = "Number of workstation nodes to launch"
  default = 1
}

variable "master_instance_count" {
  description = "Number of master nodes to launch [1, 3, 5]"
  default = 3
}

variable "agent_instance_count" {
  description = "Number of agent nodes to launch [min 3]"
  default = 4
}

variable "public_agent_instance_count" {
  description = "Number of public agent nodes to launch [min 1]"
  default = 1
}

variable "access_key" {
  description = "AWS access key"
}

variable "secret_key" {
  description = "AWS secret key"
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

variable "route53_zone_id" {
  description = "Zone ID for the Route 53 zone "
  default = "ZC91G0Y5XZWR0"
}

# amis for centoS
variable "amis" {
  default = {
    eu-central-1 = "ami-9bf712f4"
    eu-west-1 = "ami-7abd0209"
    us-west-2 = "ami-d2c924b2"
    us-east-1 = "ami-6d1c2007"
  }
}

variable "subnet_range" {
  description = "Subnet IP range"
  default = "172.31.0.0/16"
}

variable "subnet_dns" {
  description = "Subnet DNS"
  default = "172.31.0.2"
}

variable "admin_ip" {
  default = "0.0.0.0/0"
}

variable "key_name" {
  description = "Name of existing AWS key pair to use"
}

variable "prefix" {
  description = "Used for naming instances in AWS (e.g. my-dcos)"
}

variable "owner" {
  description = "AWS tag of the owner (e.g. Slack username)"
  default = "username"
}

variable "expiration" {
  description = "AWS tag of the expiration time"
  default = "8hours"
}

# specify the provider and access details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
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

output "lb_external_masters" {
  value = "${module.elb.external_masters_dns_name}"
}

output "lb_internal_masters" {
  value = "${module.elb.internal_masters_dns_name}"
}

output "lb_external_agents" {
  value = "${module.elb.external_agents_dns_name}"
}

module "workstation" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-workstation"
  instance_count = "${var.workstation_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs_master}"
  region = "${var.region}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnet_id = "${module.vpc.subnet_id}"
  iam_instance_profile = ""
  instance_type = "m3.xlarge"
  volume_size = "60"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

output "workstation_public_ips" {
    value = "${module.workstation.public_ips}"
}

output "workstation_private_ips" {
    value = "${module.workstation.private_ips}"
}

module "master" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-master"
  instance_count = "${var.master_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs_master}"
  region = "${var.region}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnet_id = "${module.vpc.subnet_id}"
  iam_instance_profile = ""
  instance_type = "m4.2xlarge"
  volume_size = "100"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

output "master_public_ips" {
    value = "${module.master.public_ips}"
}

output "master_private_ips" {
    value = "${module.master.private_ips}"
}

module "agent" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-agent"
  instance_count = "${var.agent_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs}"
  region = "${var.region}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnet_id = "${module.vpc.subnet_id}"
  iam_instance_profile = "${module.iam.agent_profile}"
  instance_type = "m4.2xlarge"
  volume_size = "100"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

output "agent_public_ips" {
    value = "${module.agent.public_ips}"
}

module "public_agent" {
  source ="./terraform/aws/instance"
  instance_name = "${var.prefix}-public_agent"
  instance_count = "${var.public_agent_instance_count}"
  amis = "${var.amis}"
  azs = "${var.azs}"
  region = "${var.region}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${module.security-groups.internal_sg}","${module.security-groups.admin_sg}"]
  subnet_id = "${module.vpc.subnet_id}"
  iam_instance_profile = "${module.iam.agent_profile}"
  instance_type = "m4.2xlarge"
  volume_size = "100"
  owner = "${var.owner}"
  expiration = "${var.expiration}"
}

output "public_agent_public_ips" {
    value = "${module.public_agent.public_ips}"
}

module "ansible" {
  source = "./terraform/aws/ansible"
  count_m = "${module.master.public_ips}"
  count_a = "${module.agent.public_ips}"
  count_p = "${module.public_agent.public_ips}"
  count_w = "${module.workstation.public_ips}"
}

output "prefix" {
  value = "${var.prefix}"
}

output "dns" {
    value = "${var.subnet_dns}"
}

output "dns_search" {
    value = "${var.region}.compute.internal"
}
