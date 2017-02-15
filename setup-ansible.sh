#!/bin/bash

# Create Ansible Config File

config_src="./ansible/ansible.cfg.template"
config_dest="./ansible.cfg"

cp -R $config_src $config_dest

echo "Path to .pem file, e.g. ~/.ssh/test_identity.pem"
read pempath

sed -i '' "s|pemfile|$pempath|g" $config_dest

# Create hosts file

hosts_src="./hosts.example"
hosts_dest="./hosts"

cp -R $hosts_src $hosts_dest

workstation_escaped=$(printf '%s\n' "`terraform output workstation_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
workstation_escaped=${workstation_escaped%?}

master_escaped=$(printf '%s\n' "`terraform output master_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
master_escaped=${master_escaped%?}

agent_escaped=$(printf '%s\n' "`terraform output agent_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
agent_escaped=${agent_escaped%?}

public_agent_escaped=$(printf '%s\n' "`terraform output public_agent_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
public_agent_escaped=${public_agent_escaped%?}

sed -i '' "s/1.0.0.1/$workstation_escaped/g" $hosts_dest
sed -i '' "s/1.0.0.2/$master_escaped/g" $hosts_dest
sed -i '' "s/1.0.0.3/$agent_escaped/g" $hosts_dest
sed -i '' "/1.0.0.4/d" $hosts_dest
sed -i '' "s/1.0.0.5/$public_agent_escaped/g" $hosts_dest

# Create setup config

setup_src="./group_vars/all.example/setup.yaml"
setup_dest="./group_vars/all/setup.yaml"

if [ -f $setup_dest ]; then
	echo "Setup file exists. Delete ./group_vars/all/setup.yaml and rerun to overwrite"
else
	cp -R $setup_src $setup_dest
	echo "Please name your cluster (e.g. dcos-ansible-test) no pipes (|)"
	read cluster_name
	sed -i '' "s|cluster-name|$cluster_name|g" $setup_dest

	echo "Enterprise DC/OS or OSS DC/OS"
        echo "Please select your choice: "
	options=("Enterprise DC/OS" "OSS DC/OS")
	select opt in "${options[@]}"
	do
		case $opt in
			"Enterprise DC/OS")
				echo "Enterprise DC/OS Selected"
				echo "Please input download URL starting with http://downloads..."
				read download_url
				sed -i '' "s|dcos-download|$download_url|g" $setup_dest
				echo "Please input customer key provided by Mesosphere like ########-####-####-####-############"
				read customer_key
				sed -i '' "s|customer-key|$customer_key|g" $setup_dest
				echo "Please select a security mode (permissive is default)"
				security_mode_opt=("strict" "permissive" "disabled")
				select security_mode in "${security_mode_opt[@]}"
				do
					sed -i '' "s|security-mode|$security_mode|g" $setup_dest && break	
				done
				echo "Select RexRay Config Method (default empty)"
				rexray_config_method_opt=("file" "empty")
				select rexray_config_method in "${rexray_config_method_opt[@]}"
				do
					sed -i '' "s|rexray-config-method|$rexray_config_method|g" $setup_dest
					#if [ $rexray_config_method = "file" ]; then
						#echo "Please input the file path and name of the rexray config"
						#read rexray_config_filename
						#sed -i '' "s|rexray-config-filename|$rexray_config_filename|g" $setup_dest
					#fi
					break
				done
				break
				;;
			"OSS DC/OS")
				echo "OSS DC/OS Selected"
				sed -i '' "s/enterprise_dcos: true/enterprise_dcos: false/g" $setup_dest	
                                echo "Please input download URL starting with http://downloads..."
                                read download_url
                                sed -i '' "s|dcos-download|$download_url|g" $setup_dest
				break
				;;
			*) echo invalid option;;
		esac
	done
	echo "Exhibitor backend (aws_s3, zookeeper, shared_filesystem, static) - if unsure select static"
	echo "Please select your choice: "
	options=("aws_s3" "zookeeper" "shared_filesystem" "static")
	select opt in "${options[@]}"
	do
		case $opt in
			"aws_s3")
				sed -i '' "s|exhibitor-backend|$opt|g" $setup_dest
				echo "aws_access_key_id:"
				read $key_id
				sed -i '' "s|key-id|$key_id|g" $setup_dest
				echo "aws_secret_access_key:"
				read $key_secret
                                sed -i '' "s|key-secret|$key_secret|g" $setup_dest
				echo "aws_region:"
				read s3_region
                                sed -i '' "s|s3-region|$s3_region|g" $setup_dest
				echo "s3_bucket:"
				read s3_bucket
                                sed -i '' "s|s3-bucket|$s3_bucket|g" $setup_dest
				echo "s3_prefix:"
				read s3_prefix
                                sed -i '' "s|s3-prefix|$s3_prefix|g" $setup_dest
				break
				;;
			"zookeeper")
                                sed -i '' "s|exhibitor-backend|$opt|g" $setup_dest
				echo "Zookeeper is hosted from workstation node, not recommended for production use without modification"
				break
				;;
			"shared_filesystem")
                                sed -i '' "s|exhibitor-backend|$opt|g" $setup_dest
				echo "Shared Filesystem is hosted from workstation node, not recommended for production use without modification"
				break
				;;
			"static")
                                sed -i '' "s|exhibitor-backend|$opt|g" $setup_dest
				break
				;;
			*) echo invalid option;;
		esac
	done
fi
 
# Create networking configuration

network_src="./group_vars/all.example/networking.yaml"
network_dest="./group_vars/all/networking.yaml"

cp -R $network_src $network_dest

workstation_escaped=$(printf '%s\n' "`terraform output workstation_private_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
workstation_escaped=${workstation_escaped%?}

master_escaped=$(printf '%s\n' "`terraform output master_private_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
master_escaped=${master_escaped%?}

dns=`terraform output dns`
dns_search=`terraform output dns_search`

sed -i '' "s/1.0.0.1/$workstation_escaped/g" $network_dest
sed -i '' "s/1.0.0.2/$master_escaped/g" $network_dest

sed -i '' "s/8.8.4.4/$dns/g" $network_dest
sed -i '' "s/None/$dns_search/g" $network_dest
