variable "count_m" {}
variable "count_a" {}
variable "count_p" {}
variable "count_w" {}

resource "null_resource" "cluster" {

  # Changes to any instance of the cluster requires adjusting the ansible configuration
  triggers {
    count_m = "${var.count_m}"
    count_a = "${var.count_a}"
    count_p = "${var.count_p}"
    count_w = "${var.count_w}"
  }

  provisioner "local-exec" {
      command = "bash prepare-ansible.sh"
  }
}
