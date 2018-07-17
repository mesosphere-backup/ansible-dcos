RM := rm -f
TERRAFORM_INSTALLER_URL := github.com/dcos/terraform-dcos

# Set PATH to include local dir for locally downloaded binaries.
export PATH := .:$(PATH)

# Get the path to relvant binaries.
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
	$(error "$n$nNo python3 command in $(PATH).$n$nPlease install via 'brew install python3' on MacOS.$n$n")
endif

.PHONY: azure
azure: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/azure; \
	cp ../resources/desired_cluster_profile.azure desired_cluster_profile; \
	cp ../resources/override.azure.tf override.tf; \
	../scripts/kubeapi-proxy-azure.sh; \
	rm -f desired_cluster_profile.tfvars.example

.PHONY: aws
aws: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/aws; \
	cp ../resources/desired_cluster_profile.aws desired_cluster_profile; \
	cp ../resources/override.aws.tf override.tf; \
	../scripts/kubeapi-proxy-aws.sh; \
	rm -f desired_cluster_profile.tfvars.example

.PHONY: gcp
gcp: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/gcp; \
	cp ../resources/desired_cluster_profile.gcp desired_cluster_profile; \
	cp ../resources/override.gcp.tf override.tf; \
	../scripts/kubeapi-proxy-gcp.sh; \
	rm -f desired_cluster_profile.tfvars.example

.PHONY: install-k8s
install-k8s: check-ansible
	ansible-playbook -i inventory.py plays/kubernetes.yml

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

.PHONY: clean
clean:
	$(RM) -r .deploy dcos kubectl
