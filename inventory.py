#!/usr/bin/env python3
'''
dynamic inventory script to parse terraform output
'''

import json
import subprocess
import argparse

class TerraformInventory(object):

    def _empty_inventory(self):
        return {"_meta": {"hostvars": {}}}

    def parse_cli_args(self):
        ''' Command line argument processing '''

        parser = argparse.ArgumentParser(description='Produce an Ansible Inventory file based on Terraform Output')
        parser.add_argument('--list', action='store_true', default=True, help='List instances (default: True)')
        parser.add_argument('--host', action='store', help='Get all the variables about a specific instance')
        self.args = parser.parse_args()

    def push_hosts(self, my_dict, key, element):
        ''' Push hostname entries to a group '''

        parent_group = my_dict.setdefault(key, {})
        parent_group.update({"hosts": element})

    def push_var(self, my_dict, key, element):
        ''' Push variables to a group '''

        parent_group = my_dict.setdefault(key, {})
        var_groups = parent_group.setdefault('vars', {})
        var_groups.update(element)

    def push_child(self, my_dict, key, element):
        ''' Push a group as a child of another group. '''

        parent_group = my_dict.setdefault(key, {})
        child_groups = parent_group.setdefault('children', [])
        if element not in child_groups:
            child_groups.append(element)

    def parse_terraform(self):
        ''' Retrieve json output from cmd and parse instances and variables '''

        cmd_read = subprocess.getoutput("cd .deploy && terraform output -json")
        terraform_data = json.loads(cmd_read)

        for entry in terraform_data:

            # Add group bootstraps
            if entry == 'bootstrap_public_ips':
                self.push_hosts(self.inventory, 'bootstraps', terraform_data['bootstrap_public_ips']['value'].split())
                self.push_child(self.inventory, 'common', 'bootstraps')

            # Add group masters
            elif entry == 'master_public_ips':
                self.push_hosts(self.inventory, 'masters', terraform_data['master_public_ips']['value'])
                self.push_child(self.inventory, 'common', 'masters')

            # Add group agents
            elif entry == 'agent_public_ips':
                self.push_hosts(self.inventory, 'agents', terraform_data['agent_public_ips']['value'])
                self.push_child(self.inventory, 'common', 'agents')

            # Add group public agents
            elif entry == 'public_agent_public_ips':
                self.push_hosts(self.inventory, 'agent_publics', terraform_data['public_agent_public_ips']['value'])
                self.push_child(self.inventory, 'common', 'agent_publics')

            # Add variables
            elif entry == 'bootstrap_private_ips':
                self.push_var(self.inventory, 'common', {"dcos_bootstrap_ip": terraform_data['bootstrap_private_ips']['value']})

            elif entry == 'master_private_ips':
                self.push_var(self.inventory, 'common', {"dcos_master_list": terraform_data['master_private_ips']['value']})

            elif entry == 'dns_resolvers':
                self.push_var(self.inventory, 'common', {"dcos_resolvers": terraform_data['dns_resolvers']['value'] })

            elif entry == 'dns_search':
                self.push_var(self.inventory, 'common', {"dcos_dns_search": terraform_data['dns_search']['value'] })

            elif entry == 'lb_internal_masters':
                self.push_var(self.inventory, 'common', {"dcos_exhibitor_address": terraform_data['lb_internal_masters']['value'] })

            elif entry == 'cluster_prefix':
                self.push_var(self.inventory, 'common', {"dcos_s3_prefix": terraform_data['cluster_prefix']['value']})
                self.push_var(self.inventory, 'common', {"dcos_exhibitor_azure_prefix": terraform_data['cluster_prefix']['value']})

            elif entry == 'ip_detect':
                self.push_var(self.inventory, 'common', {"dcos_iaas_target": terraform_data['ip_detect']['value']})

    def json_format_dict(self, data, pretty=False):
        ''' Converts a dict to a JSON object and dumps it as a formatted string '''

        if pretty:
            return json.dumps(data, sort_keys=True, indent=2)
        else:
            return json.dumps(data)

    def __init__(self):
        ''' Main execution path '''

        # Initialize inventory
        self.inventory = self._empty_inventory()

        # Read settings and parse CLI arguments
        self.parse_cli_args()

        # Parse hosts and variables form Terraform output
        self.parse_terraform()

        # Data to print
        if self.args.host:
            data_to_print = self._empty_inventory()

        elif self.args.list:
            # Display list of instances for inventory
            data_to_print = self.json_format_dict(self.inventory, True)

        print(data_to_print)

if __name__ == '__main__':
    # Run the script
    TerraformInventory()
