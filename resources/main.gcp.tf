provider "google" {}

module "dcos-infrastructure" {
  source  = "dcos-terraform/infrastructure/gcp"
  version = "~> 0.0"

  name_prefix = "${var.cluster_name}"

  infra_dcos_instance_os    = "${var.dcos_instance_os}"
  infra_public_ssh_key_path = "${var.ssh_public_key_file}"

  bootstrap_image            = "${var.bootstrap_gcp_image}"
  bootstrap_machine_type     = "${var.bootstrap_machine_type}"
  bootstrap_dcos_instance_os = "${var.bootstrap_os}"
  bootstrap_disk_size        = "${var.bootstrap_root_volume_size}"
  bootstrap_disk_type        = "${var.bootstrap_root_volume_type}"

  master_image            = "${var.masters_gcp_image}"
  master_machine_type     = "${var.masters_machine_type}"
  master_dcos_instance_os = "${var.masters_os}"
  master_disk_size        = "${var.masters_root_volume_size}"
  master_disk_type        = "pd-ssd"

  private_agent_image            = "${var.private_agents_gcp_image}"
  private_agent_machine_type     = "${var.private_agents_machine_type}"
  private_agent_dcos_instance_os = "${var.private_agents_os}"
  private_agent_disk_size        = "${var.private_agents_root_volume_size}"
  private_agent_disk_type        = "${var.private_agents_root_volume_type}"

  public_agent_image            = "${var.private_agents_gcp_image}"
  public_agent_machine_type     = "${var.private_agents_machine_type}"
  public_agent_dcos_instance_os = "${var.private_agents_os}"
  public_agent_disk_size        = "${var.private_agents_root_volume_size}"
  public_agent_disk_type        = "${var.private_agents_root_volume_type}"

  num_masters        = "${var.num_masters}"
  num_private_agents = "${var.num_private_agents}"
  num_public_agents  = "${var.num_public_agents}"
  admin_ips          = "${var.admin_ips}"

  # labels                      = "${var.labels}"

  providers = {
    google = "google"
  }
}