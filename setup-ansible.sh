#!/bin/bash

cp -R ./hosts.example ./hosts

workstation_escaped=$(printf '%s\n' "`terraform output workstation_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
workstation_escaped=${workstation_escaped%?}

master_escaped=$(printf '%s\n' "`terraform output master_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
master_escaped=${master_escaped%?}

agent_escaped=$(printf '%s\n' "`terraform output agent_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
agent_escaped=${agent_escaped%?}

public_agent_escaped=$(printf '%s\n' "`terraform output public_agent_public_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
public_agent_escaped=${public_agent_escaped%?}

sed -i '' "s/\${workstation_public_ips}/$workstation_escaped/g" hosts
sed -i '' "s/\${master_public_ips}/$master_escaped/g" hosts
sed -i '' "s/\${agent_public_ips}/$agent_escaped/g" hosts
sed -i '' "s/\${public_agent_public_ips}/$public_agent_escaped/g" hosts

cp -R ./group_vars/all.example/networking ./group_vars/all/networking

workstation_escaped=$(printf '%s\n' "`terraform output workstation_private_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
workstation_escaped=${workstation_escaped%?}

master_escaped=$(printf '%s\n' "`terraform output master_private_ips`" | sed 's,[\/&],\\&,g;s/$/\\/')
master_escaped=${master_escaped%?}

sed -i '' "s/\${workstation_private_ips}/$workstation_escaped/g" group_vars/all/networking
sed -i '' "s/\${master_private_ips}/$master_escaped/g" group_vars/all/networking
