#!/bin/bash

function escape()
{
  local __resultvar=$1
  local result=`terraform output $1`
  result=$(printf '%s\n' "$result" | sed 's/^o://g;s,[\/&],\\&,g;s/$/\\/')
  result=${result%?}
  eval $__resultvar="'$result'"
}

# Create ansible config file

ansiblecfg_src="./ansible.cfg.example"
ansiblecfg_dest="./ansible.cfg"

cp -R $ansiblecfg_src $ansiblecfg_dest

# Create hosts file

hosts_src="./hosts.example"
hosts_dest="./hosts"

cp -R $hosts_src $hosts_dest

escape workstation_public_ips
escape master_public_ips
escape agent_public_ips
escape public_agent_public_ips

sed -i '' "s/1.0.0.1/$workstation_public_ips/g" $hosts_dest
sed -i '' "s/1.0.0.2/$master_public_ips/g" $hosts_dest
sed -i '' "s/1.0.0.3/$agent_public_ips/g" $hosts_dest
sed -i '' "/1.0.0.4/d" $hosts_dest
sed -i '' "s/1.0.0.5/$public_agent_public_ips/g" $hosts_dest

# Create networking configuration

network_src="./group_vars/all.example/networking.yaml"
network_dest="./group_vars/all/networking.yaml"

mkdir -p ./group_vars/all/
cp -R $network_src $network_dest

escape workstation_private_ips
escape master_private_ips

escape dns
escape dns_search
escape lb_internal_masters

sed -i '' "s/1.0.0.1/$workstation_private_ips/g" $network_dest
sed -i '' "s/1.0.0.2/$master_private_ips/g" $network_dest

sed -i '' "s/8.8.4.4/$dns/g" $network_dest
sed -i '' "s/None/$dns_search/g" $network_dest
sed -i '' "s/masterlb.internal/$lb_internal_masters/g" $network_dest

# set prefix name for S3 bucket

escape prefix
echo ""
echo "# Prefix to store exhibitor state in s3 bucket (must be unique per cluster)" >> $network_dest
echo "s3_prefix: \"$prefix\"" >> $network_dest
