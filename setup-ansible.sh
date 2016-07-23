#!/bin/bash

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
