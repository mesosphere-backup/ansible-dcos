RM := rm -f

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
	cp ../resources/cluster_profile.azurerm.tfvars cluster_profile.tfvars; \
	cp ../resources/main.azurerm.tf main.tf; \
	cp ../resources/outputs.azurerm.tf outputs.tf; \
	cp ../resources/variables.azurerm.tf variables.tf; \
	$(TERRAFORM_CMD) init

.PHONY: aws
aws: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	cp ../resources/cluster_profile.aws.tfvars cluster_profile.tfvars; \
	cp ../resources/main.aws.tf main.tf; \
	cp ../resources/outputs.aws.tf outputs.tf; \
	cp ../resources/variables.aws.tf variables.tf; \
	$(TERRAFORM_CMD) init
	
.PHONY: gcp
gcp: clean check-terraform
	mkdir .deploy
	cd .deploy; \
	cp ../resources/cluster_profile.gcp.tfvars cluster_profile.tfvars; \
	cp ../resources/main.gcp.tf main.tf; \
	cp ../resources/outputs.gcp.tf outputs.tf; \
	cp ../resources/variables.gcp.tf variables.tf; \
	$(TERRAFORM_CMD) init

.PHONY: plan-infra
plan-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) plan -var-file cluster_profile.tfvars

.PHONY: launch-infra
launch-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) apply -var-file cluster_profile.tfvars

.PHONY: destroy-infra
destroy-infra: check-terraform
	cd .deploy; \
	$(TERRAFORM_CMD) destroy $(TERRAFORM_DESTROY_ARGS) -var-file cluster_profile.tfvars

.PHONY: ansible-ping
ansible-ping: check-python3 check-ansible
	ansible all -i inventory.py -m ping

.PHONY: ansible-deploy
ansible-deploy: check-python3 check-ansible ansible-ping
	ansible-playbook -i inventory.py dcos.yml

.PHONY: plan
plan: plan-infra

.PHONY: deploy
deploy: launch-infra ansible-deploy

.PHONY: ui
ui:
	cd .deploy; \
	$(OPEN) https://`terraform output "lb_external_masters"`

.PHONY: public-lb
public-lb:
	cd .deploy; \
	$(OPEN) http://`terraform output "lb_external_agents"`

.PHONY: destroy
destroy: destroy-infra

.PHONY: clean
clean:
	$(RM) -r .deploy
