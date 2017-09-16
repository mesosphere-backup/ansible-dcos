# Changelog

## v.2.2-alpha

* Tested with DC/OS 1.10
* Updated configuration for rexray 0.9.0
* Removed rarely used scripts and plays
* Adds support for public ip detection on aws
* Fix for #8 Default bootstrap folder is not part of /tmp

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
