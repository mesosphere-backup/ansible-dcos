# Changelog

## v0.7.0-dcos-1.11

* Install DC/OS Packages with Ansible and use Kubernetes as the first example
* Added Ansible module for package installation (https://github.com/dcos-labs/ansible-dcos-module)
* Removed instructions for the SSH tunnel (it's not really needed anymore for the current versions of the Kubernetes package)
* Separate installation of dcos cli and kubectl
* Dedicated Kubernetes role roles/package/kubernetes/ that is using the package install module
* Installs ifconfig to address issues with MESOS-6822
* Update Kubernetes to  framework version 1.2.0-1.10.5
* Add support for 6443 port in Terraform
* Replace unsupported docker-py with current docker module.
* Added yum-utils to common tasks
* Bumps docker version to 17.06.2.ce
* Removes Docker live restore because of issues with MESOS-6480

## v0.6.1-dcos-1.11

* Update Kubernetes framework to GA
* Bump Kubernetes version to v1.9.6
* Add Kubernetes upgrade doc
* Other docs improvements
* Major refactoring around ansible variables and removal of code duplication

## v0.6.0-dcos-1.11

* Removing Terraform and referencing https://github.com/dcos/terraform-dcos for setting up the infrastructure
* Adds support for GCP and Azure
* Enables IPv6
* Support of Fault Domain Awareness
* Support of License Keys (in DC/OS Enterprise 1.11)
* Bumps Docker version to 17.05.0.ce
* Adopts Makefile approach for easy setup
* Docs improvements
* #8 On-Premises: added possibility to use other device names for existing network interface

## v0.5.0-dcos-1.10

* Installs and disables dnsmasq
* Disables source/dest for AWS instances check in order to get CNI/Calico working properly
* Tested with DC/OS 1.10.2
* Migrated repo to https://github.com/dcos-labs/terraform-ansible-dcos

## v0.4.0-alpha

* #5 Adds Dynamic Inventory to read from Terraform state
* Simplified directory structure for variables
* Moves Docker to it's own Ansible role, set sane defaults and makes the version configurable
* Installs firewalld in order to proper disable it afterwards

## v0.3.0-alpha

* Tested with DC/OS 1.10
* Updated configuration for rexray 0.9.0
* Removed rarely used scripts and plays
* Adds support for public ip detection on aws
* Fixes uninstall script and sets temporary nameserver
* Fix for #8 Default bootstrap folder is not part of /tmp
* Terraform: New AMIs for Centos 7.3

## v0.2.1-alpha

* Tested with DC/OS 1.9
* Install Docker 1.13
* Improved documentation

## v0.2.0-alpha

* Terraform
  * Restructure Terraform with modules  
  * Support for Availability Zones
    * Spread Private Agents across different AZ
    * Keep Masters in the same AZ
  * Create Internal LoadBalancer for Masters
  * Create External LoadBalancer for Masters
  * Create External LoadBalancer for Public Agents
  * Put in name prefix in front of every AWS entity
  * Adds Security Groups for each Roles instances, elbs
  * Delete EBS volumes after instance termination

* Ansible
  * Read Availability Zone and set Mesos attribute for each agent
  * Support for internal Master LoadBalancer
  * Adds fix for DCOS-12332 Certificate did not match expected hostname CERT, ELB master_http_loadbalancer
  * Use prefix for the file name inside of S3 Bucket
  * Removed support for exhibitor backends: NFS and ZooKeeper
  * Preview for service deployment: Marathon-LB
  * Preview for DC/OS configuration: LDAP
  * Preview of automated upgrades for DC/OS 1.9 using the new upgrade API

## v0.1.0-alpha

* Tested with DC/OS 1.8
* Now works with Enterprise or OSS
* Parameterized setup file for Ansible (custom download location, cluster name, etc)
