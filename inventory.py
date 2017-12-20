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

        cmd_read = subprocess.getoutput("terraform output -json")
        terraform_data = json.loads(cmd_read)

        for entry in terraform_data:

            # Add group bootstraps
            if entry == 'Bootstrap Public IP Address':
                self.push_hosts(self.inventory, 'bootstraps', terraform_data['Bootstrap Public IP Address']['value'].split())
                self.push_child(self.inventory, 'common', 'bootstraps')

            # Add group masters
            if entry == 'Mesos Master Public IP':
                self.push_hosts(self.inventory, 'masters', terraform_data['Mesos Master Public IP']['value'])
                self.push_child(self.inventory, 'common', 'masters')

            # Add group agents
            if entry == 'Private Agent Public IP Address':
                self.push_hosts(self.inventory, 'agents', terraform_data['Private Agent Public IP Address']['value'])
                self.push_child(self.inventory, 'common', 'agents')

            # Add group public agents
            if entry == 'Public Agent Public IP Address':
                self.push_hosts(self.inventory, 'agents_public', terraform_data['Public Agent Public IP Address']['value'])
                self.push_child(self.inventory, 'common', 'agents_public')

            # Add variables
            elif entry == 'Bootstrap Private IP Address':
                self.push_var(self.inventory, 'common', {"bootstrap_ip": terraform_data['Bootstrap Private IP Address']['value']})

            elif entry == 'Mesos Master Private IP':
                self.push_var(self.inventory, 'common', {"master_list": terraform_data['Mesos Master Private IP']['value']})

            elif entry == 'DNS Resolvers':
                self.push_var(self.inventory, 'common', {"resolvers": terraform_data['DNS Resolvers']['value'] })

            elif entry == 'DNS Search':
                self.push_var(self.inventory, 'common', {"dns_search": terraform_data['DNS Search']['value'] })

            elif entry == 'Internal Master ELB Address':
                self.push_var(self.inventory, 'common', {"exhibitor_address": terraform_data['Internal Master ELB Address']['value'] })

            elif entry == 'Cluster Prefix':
                self.push_var(self.inventory, 'common', {"s3_prefix": terraform_data['Cluster Prefix']['value']})


            # Add defaults
            self.push_var(self.inventory, 'common', {"ip_detect": "aws"})


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
