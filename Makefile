RM := rm -f
MASTER_IP_FILE := .master_ip
MASTER_LB_IP_FILE := .master_lb_ip
TERRAFORM_INSTALLER_URL := github.com/dcos/terraform-dcos
DCOS_VERSION := 1.11
KUBERNETES_VERSION := 1.9.4

# Set PATH to include local dir for locally downloaded binaries.
export PATH := .:$(PATH)

# Get the path to relvant binaries.
DCOS_CMD := $(shell PATH=$(PATH) command -v dcos 2> /dev/null)
KUBECTL_CMD := $(shell PATH=$(PATH) command -v kubectl 2> /dev/null)
TERRAFORM_CMD := $(shell command -v terraform 2> /dev/null)
ANSIBLE_CMD := $(shell command -v ansible 2> /dev/null)
PYTHON3_CMD := $(shell command -v python3 2> /dev/null)
TERRAFORM_APPLY_ARGS ?=
TERRAFORM_DESTROY_ARGS ?=

UNAME := $(shell uname -s)
ifeq ($(UNAME),Linux)
OPEN := xdg-open
else
OPEN := open
endif

# Define a new line character to use in error strings.
define n


endef

.PHONY: get-cli
get-cli:
	$(eval export DCOS_VERSION)
	$(eval export KUBERNETES_VERSION)
	scripts/get_cli

.PHONY: check-cli
check-cli: check-terraform check-dcos check-kubectl

.PHONY: check-terraform
check-terraform:
ifndef TERRAFORM_CMD
	$(error "$n$nNo terraform command in $(PATH).$n$nPlease install via 'brew install terraform' on MacOS, or download from https://www.terraform.io/downloads.html.$n$n")
endif

.PHONY: check-ansible
check-ansible:
ifndef ANSIBLE_CMD
	$(error "$n$nNo ansible command in $(PATH).$n$nPlease install via 'brew install ansible' on MacOS, or download from http://docs.ansible.com/ansible/latest/intro_installation.html.$n$n")
endif

.PHONY: check-python3
check-python3:
ifndef PYTHON3_CMD
	$(error "$n$nNo ansible command in $(PATH).$n$nPlease install via 'brew install ansible' on MacOS, or download from http://docs.ansible.com/ansible/latest/intro_installation.html.$n$n")
endif

.PHONY: check-dcos
check-dcos:
ifndef DCOS_CMD
	$(error "$n$nNo dcos command in $(PATH).$n$nPlease run 'make get-cli' to download required binaries.$n$n")
endif

.PHONY: check-kubectl
check-kubectl:
ifndef KUBECTL_CMD
	$(error "$n$nNo kubectl command in $(PATH).$n$nPlease run 'make get-cli' to download required binaries.$n$n")
endif

.PHONY: azure
azure: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/azure; \
	cp ../resources/override.azure.tf override.tf; \
	cp ../resources/desired_cluster_profile.azure desired_cluster_profile; \
	cp ../resources/options.json.azure options.json; \
	rm -f desired_cluster_profile.tfvars.example

.PHONY: aws
aws: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/aws; \
	cp ../resources/override.aws.tf override.tf; \
	cp ../resources/desired_cluster_profile.aws desired_cluster_profile; \
	cp ../resources/options.json.aws options.json; \
	rm -f desired_cluster_profile.tfvars.example

.PHONY: gcp
gcp: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/gcp; \
	cp ../resources/override.gcp.tf override.tf; \
	cp ../resources/desired_cluster_profile.gcp desired_cluster_profile; \
	cp ../resources/options.json.gcp options.json; \
	rm -f desired_cluster_profile.tfvars.example

.PHONY: onprem
onprem:
	mkdir .deploy
	cd .deploy; \
	cp ../resources/options.json.onprem options.json

.PHONY: setup-cli
setup-cli: check-dcos
	$(call get_master_lb_ip)
	$(DCOS_CMD) cluster setup https://$(MASTER_LB_IP)

.PHONY: get-master-ip
get-master-ip:
	$(call get_master_ip)
	@echo $(MASTER_IP)

define get_master_ip
$(shell test -f $(MASTER_IP_FILE) || \
	$(TERRAFORM_CMD) output -state=.deploy/terraform.tfstate "master_public_ips" | head -1 | cut -f 1 -d ',' > $(MASTER_IP_FILE))
$(eval MASTER_IP := $(shell cat $(MASTER_IP_FILE)))
endef

.PHONY: get-master-lb-ip
get-master-lb-ip: check-terraform
	$(call get_master_lb_ip)
	@echo $(MASTER_LB_IP)

define get_master_lb_ip
$(shell test -f $(MASTER_LB_IP_FILE) || \
	$(TERRAFORM_CMD) output -state=.deploy/terraform.tfstate "lb_external_masters" > $(MASTER_LB_IP_FILE))
$(eval MASTER_LB_IP := $(shell cat $(MASTER_LB_IP_FILE)))
endef

.PHONY: install-k8s
install-k8s: check-dcos
	$(DCOS_CMD) package install --yes kubernetes --options=./.deploy/options.json

.PHONY: uninstall-k8s
uninstall-k8s: check-dcos
	$(DCOS_CMD) package uninstall --yes kubernetes

.PHONY: plan-infra
plan-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) plan -var-file desired_cluster_profile -var state=none

.PHONY: launch-infra
launch-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) apply -var-file desired_cluster_profile -var state=none

.PHONY: destroy-infra
destroy-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) destroy $(TERRAFORM_DESTROY_ARGS) -var-file desired_cluster_profile

.PHONY: ansible-ping
ansible-ping: check-python3 check-ansible
	ansible all -i inventory.py -m ping

.PHONY: ansible-install
ansible-install: check-python3 check-ansible ansible-ping
	ansible-playbook -i inventory.py plays/install.yml

kubectl-config: check-kubectl
	$(DCOS_CMD) kubernetes kubeconfig

kubectl-tunnel:
	$(KUBECTL_CMD) config set-cluster dcos-k8s --server=http://localhost:9000
	$(KUBECTL_CMD) config set-context dcos-k8s --cluster=dcos-k8s --namespace=default
	$(KUBECTL_CMD) config use-context dcos-k8s
	$(call get_master_ip)
	ssh -4 -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "ServerAliveInterval=120" \
		-N -L 9000:apiserver-insecure.kubernetes.l4lb.thisdcos.directory:9000 \
		centos@$(MASTER_IP)

.PHONY: ansible-uninstall
ansible-uninstall: check-python3 check-ansible ansible-ping
	ansible-playbook -i inventory.py plays/uninstall.yml

.PHONY: plan
plan: plan-infra

.PHONY: deploy
deploy: launch-infra ansible-install

.PHONY: ui
ui:
	cd .deploy; \
	$(OPEN) https://`terraform output "lb_external_masters"`

.PHONY: public-lb
public-lb:
	cd .deploy; \
	$(OPEN) http://`terraform output "lb_external_agents"`

.PHONY: uninstall
uninstall: ansible-uninstall

.PHONY: destroy
destroy: destroy-infra
	$(RM) $(MASTER_IP_FILE)
	$(RM) $(MASTER_LB_IP_FILE)

.PHONY: clean
clean:
	$(RM) -r .deploy dcos kubectl
