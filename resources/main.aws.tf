provider "aws" {
    region = "${var.aws_region}"
    profile = "${var.aws_profile}"
}

module "dcos-infrastructure" {
  source  = "dcos-terraform/infrastructure/aws"
  version = "~> 0.0"

  admin_ips                                  = "${var.admin_ips}"
  availability_zones                         = "${var.availability_zones}"
  aws_ami                                    = "${var.aws_ami}"
  aws_key_name                               = "${var.aws_key_name}"
  bootstrap_associate_public_ip_address      = "${var.bootstrap_associate_public_ip_address}"
  bootstrap_aws_ami                          = "${var.bootstrap_aws_ami}"
  bootstrap_instance_type                    = "${var.bootstrap_instance_type}"
  bootstrap_os                               = "${var.bootstrap_os}"
  bootstrap_root_volume_size                 = "${var.bootstrap_root_volume_size}"
  bootstrap_root_volume_type                 = "${var.bootstrap_root_volume_type}"
  cluster_name                               = "${var.cluster_name}"
  dcos_instance_os                           = "${var.dcos_instance_os}"
  masters_associate_public_ip_address        = "${var.masters_associate_public_ip_address}"
  masters_aws_ami                            = "${var.masters_aws_ami}"
  masters_instance_type                      = "${var.masters_instance_type}"
  masters_os                                 = "${var.masters_os}"
  masters_root_volume_size                   = "${var.masters_root_volume_size}"
  num_masters                                = "${var.num_masters}"
  num_private_agents                         = "${var.num_private_agents}"
  num_public_agents                          = "${var.num_public_agents}"
  private_agents_associate_public_ip_address = "${var.private_agents_associate_public_ip_address}"
  private_agents_aws_ami                     = "${var.private_agents_aws_ami}"
  private_agents_instance_type               = "${var.private_agents_instance_type}"
  private_agents_os                          = "${var.private_agents_os}"
  private_agents_root_volume_size            = "${var.private_agents_root_volume_size}"
  private_agents_root_volume_type            = "${var.private_agents_root_volume_type}"
  public_agents_associate_public_ip_address  = "${var.public_agents_associate_public_ip_address}"
  public_agents_aws_ami                      = "${var.public_agents_aws_ami}"
  public_agents_instance_type                = "${var.public_agents_instance_type}"
  public_agents_os                           = "${var.public_agents_os}"
  public_agents_root_volume_size             = "${var.public_agents_root_volume_size}"
  public_agents_root_volume_type             = "${var.public_agents_root_volume_type}"
  ssh_public_key                             = "${var.ssh_public_key}"
  tags                                       = "${var.tags}"

  providers = {
    aws = "aws"
  }
}