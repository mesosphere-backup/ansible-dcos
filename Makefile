.PHONY: check-terraform check-ansible azure aws gcp plan-infra launch-infra destroy-infra ansible-ping ansible-install ansible-uninstall plan deploy ui uninstall destroy clean

RM := rm -f
TERRAFORM_INSTALLER_URL := github.com/dcos/terraform-dcos

# Set PATH to include local dir for locally downloaded binaries.
export PATH := .:$(PATH)

# Get the path to relvant binaries.
TERRAFORM_CMD := $(shell command -v terraform 2> /dev/null)
ANSIBLE_CMD := $(shell command -v ansible 2> /dev/null)

UNAME := $(shell uname -s)
ifeq ($(UNAME),Linux)
OPEN := xdg-open
else
OPEN := open
endif

# Define a new line character to use in error strings.
define n


endef

check-terraform:
ifndef TERRAFORM_CMD
	$(error "$n$nNo terraform command in $(PATH).$n$nPlease install via 'brew install terraform' on MacOS, or download from https://www.terraform.io/downloads.html.$n$n")
endif

check-ansible:
ifndef ANSIBLE_CMD
	$(error "$n$nNo ansible command in $(PATH).$n$nPlease install via 'brew install ansible' on MacOS, or download from http://docs.ansible.com/ansible/latest/intro_installation.html.$n$n")
endif

azure: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/azure; \
	cp ../resources/override.azure.tf override.tf;

aws: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/aws; \
	cp ../resources/override.aws.tf override.tf;

gcp: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	$(TERRAFORM_CMD) init -from-module $(TERRAFORM_INSTALLER_URL)/gcp; \
	cp ../resources/override.gcp.tf override.tf;

plan-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) plan -var-file ../desired_cluster_profile -var state=none

launch-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) apply -var-file ../desired_cluster_profile -var state=none -auto-approve

destroy-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) destroy -var-file ../desired_cluster_profile -force

ansible-ping: check-ansible
	ansible all -i inventory.py -m ping

ansible-install: check-ansible ansible-ping
	ansible-playbook -i inventory.py plays/install.yml

ansible-uninstall: check-ansible ansible-ping
	ansible-playbook -i inventory.py plays/uninstall.yml

plan: plan-infra

deploy: launch-infra ansible-install

ui:
	cd .deploy; \
	$(OPEN) https://`terraform output "lb_external_masters"`

public-lb:
	cd .deploy; \
	$(OPEN) https://`terraform output "lb_external_agents"`

uninstall: ansible-uninstall

destroy: destroy-infra

clean:
	$(RM) -r .deploy
