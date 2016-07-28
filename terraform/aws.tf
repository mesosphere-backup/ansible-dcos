### Variables ###

# Define instance count of the DC/OS nodes

variable "workstation_instance_count" {
  description = "Number of workstation nodes to launch"
  default = 1
}

variable "master_instance_count" {
  description = "Number of master nodes to launch"
  default = 1
}


variable "agent_instance_count" {
  description = "Number of agent nodes to launch"
  default = 4
}

variable "public_agent_instance_count" {
  description = "Number of public agent nodes to launch"
  default = 1
}

variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default = "eu-central-1"
}

# AMIs for CentOS

variable "amis" {
    default = {
        eu-central-1 = "ami-9bf712f4"
        us-west-2 = "	ami-d2c924b2"
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

variable "sg_name" {
  default = "dcos_sg"
  description = "Tag Name for sg"
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "owner" {
  description = "Just a tag of the owner"
  default = "jan.repnak"
}

variable "expiration" {
  description = "Just a tag of the expiration time"
  default = "8hours"
}

### Outputs ###

output "workstation_public_ips" {
    value = "${join("\n", aws_instance.workstations.*.public_ip)}"
}

output "workstation_private_ips" {
    value = "${join("\n  - ", aws_instance.workstations.*.private_ip)}"
}

output "master_public_ips" {
    value = "${join("\n", aws_instance.masters.*.public_ip)}"
}

output "master_private_ips" {
    value = "${join("\n  - ", aws_instance.masters.*.private_ip)}"
}

output "agent_public_ips" {
    value = "${join("\n", aws_instance.agents.*.public_ip)}"
}

output "public_agent_public_ips" {
    value = "${join("\n", aws_instance.public_agents.*.public_ip)}"
}

output "dns" {
    value = "${var.subnet_dns}"
}

output "dns_search" {
    value = "${var.region}.compute.internal"
}

### Create Environment ###

# Specify the provider and access details
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "dcos_vpc" {
  cidr_block = "${var.subnet_range}"
  enable_dns_support = true
  enable_dns_hostnames = true

}

# Create a subnet to launch our instances into
resource "aws_subnet" "dcos_subnet" {

  vpc_id = "${aws_vpc.dcos_vpc.id}"
  cidr_block = "${var.subnet_range}"
  map_public_ip_on_launch = true

}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.dcos_vpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.dcos_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Key pair
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Define IAM role to create external volumes on AWS
resource "aws_iam_instance_profile" "agent_profile" {
  name = "agent_profile"
  roles = ["${aws_iam_role.dcos_agent_role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "agent_policy" {
    name = "agent_policy"
    role = "${aws_iam_role.dcos_agent_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:CreateTags",
                "ec2:DescribeInstances",
                "ec2:CreateVolume",
                "ec2:DeleteVolume",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumeAttribute",
                "ec2:CreateSnapshot",
                "ec2:CopySnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSnapshotAttribute"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role" "dcos_agent_role" {
    name = "dcos_agent_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Default security group
resource "aws_security_group" "dcos_sg" {
  name = "main_dcos_sg"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_vpc.dcos_vpc.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.subnet_range}"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.admin_ip}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create Workstations
resource "aws_instance" "workstations" {
  instance_type = "t2.micro"
  ami = "${lookup(var.amis, var.region)}"

  count = "${var.workstation_instance_count}"
  key_name = "${aws_key_pair.auth.id}"
  subnet_id = "${aws_subnet.dcos_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.dcos_sg.id}"]
  associate_public_ip_address = true

  tags {
          Name = "dcos-workstation"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }

}

# Create Masters
resource "aws_instance" "masters" {
  instance_type = "m3.medium"
  ami = "${lookup(var.amis, var.region)}"

  count = "${var.master_instance_count}"
  key_name = "${aws_key_pair.auth.id}"
  subnet_id = "${aws_subnet.dcos_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.dcos_sg.id}"]
  associate_public_ip_address = true

  tags {
          Name = "dcos-master"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }

#  root_block_device {
#    volume_size = 20
#  }

}

# Create Agents
resource "aws_instance" "agents" {
  instance_type = "m3.xlarge"
  ami = "${lookup(var.amis, var.region)}"

  count = "${var.agent_instance_count}"
  key_name = "${aws_key_pair.auth.id}"
  subnet_id = "${aws_subnet.dcos_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.dcos_sg.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.agent_profile.name}"

  tags {
          Name = "dcos-agent"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }

}

# Create Public Agents
resource "aws_instance" "public_agents" {
  instance_type = "m3.xlarge"
  ami = "${lookup(var.amis, var.region)}"

  count = "${var.public_agent_instance_count}"
  key_name = "${aws_key_pair.auth.id}"
  subnet_id = "${aws_subnet.dcos_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.dcos_sg.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.agent_profile.name}"

  tags {
          Name = "dcos-public_agent"
          owner = "${var.owner}"
          expiration = "${var.expiration}"
      }

}
