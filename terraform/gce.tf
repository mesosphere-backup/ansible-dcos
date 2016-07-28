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

variable "region" {
    default = "europe-west1"
}

variable "zone" {
    default = "europe-west1-b"
}

variable "volume_size" {
    default = "15"
}

variable "network_ipv4" {
    default = "172.31.0.0/16"
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "ssh_user" {
    default = "centos"
}

### Outputs ###


### Create Environment ###

# Specify the provider and access details
provider "google" {
  credentials = "${file("account.json")}"
  project = "dcos-ansible"
  region = "${var.region}"
}

# Network
resource "google_compute_network" "dcos-network" {
  name = "dcos-network"
  ipv4_range = "${var.network_ipv4}"
}

# Create Workstations
resource "google_compute_instance" "workstations" {
  name = "dcos-workstation"
  description = "dcos-workstation"

  machine_type = "n1-standard-1"
  zone = "${var.zone}"
  can_ip_forward = false
  tags = ["dcos-workstation", "workstation"]

  disk {
    image = "centos-7-v20160119"
    size = "${var.volume_size}"
    auto_delete = true
  }

  /*disk {
    disk = "${element(google_compute_disk.mi-control-lvm.*.name, count.index)}"
    auto_delete = false

    # make disk available as "/dev/disk/by-id/google-lvm"
    # NOTE: "google-" prefix is auto added
    device_name = "lvm"
  }*/

  network_interface {
    network = "${google_compute_network.dcos-network.name}"
    access_config {}
  }

  metadata {
    dc = "gce"
    role = "workstation"
    sshKeys = "${var.ssh_user}:${file(var.public_key_path)} ${var.ssh_user}"
    ssh_user = "${var.ssh_user}"
  }

}
