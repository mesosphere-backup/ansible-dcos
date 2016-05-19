#!/bin/bash


# Create hosts file
cp -R ./hosts.example ./hosts

workstation_escaped=$(printf '%s\n' "`terraform output workstation_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
workstation_escaped=${workstation_escaped%?}

master_escaped=$(printf '%s\n' "`terraform output master_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
master_escaped=${master_escaped%?}

agent_escaped=$(printf '%s\n' "`terraform output agent_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
agent_escaped=${agent_escaped%?}

public_agent_escaped=$(printf '%s\n' "`terraform output public_agent_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
public_agent_escaped=${public_agent_escaped%?}

sed -i '' "s/1.0.0.1/$workstation_escaped/g" hosts
sed -i '' "s/1.0.0.2/$master_escaped/g" hosts
sed -i '' "s/1.0.0.3/$agent_escaped/g" hosts
sed -i '' "/1.0.0.4/d" hosts
sed -i '' "s/1.0.0.5/$public_agent_escaped/g" hosts


# Create networking configuration

cp -R ./group_vars/all.example/networking ./group_vars/all/networking

workstation_escaped=$(printf '%s\n' "`terraform output workstation_private_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
workstation_escaped=${workstation_escaped%?}

master_escaped=$(printf '%s\n' "`terraform output master_private_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
master_escaped=${master_escaped%?}

dns=`terraform output dns`
dns_search=`terraform output dns_search`

sed -i '' "s/1.0.0.1/$workstation_escaped/g" group_vars/all/networking
sed -i '' "s/1.0.0.2/$master_escaped/g" group_vars/all/networking

sed -i '' "s/8.8.4.4/$dns/g" group_vars/all/networking
sed -i '' "s/None/$dns_search/g" group_vars/all/networking
