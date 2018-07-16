"""
Action plugin to configure a DC/OS cluster.
Uses the Ansible host to connect directly to DC/OS.
"""

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json
import subprocess
import tempfile
import time
import os
import sys

from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleActionFail

# to prevent duplicating code, make sure we can import common stuff
sys.path.append(os.getcwd())
from action_plugins.common import ensure_dcos, run_command, _dcos_path

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

def ensure_dcos_edgelb(instance_name):
    """Check whether the dcos[cli] edgelb extension is installed."""

    try:
        subprocess.check_output([
            'dcos',
            'edgelb',
            '--name=' + instance_name,
            'ping'
            ], env=_dcos_path()).decode()
    except:
        display.vvv("dcos edgelb: not installed")
        install_dcos_edgelb_cli()
        subprocess.check_output([
            'dcos',
            'edgelb',
            '--name=' + instance_name,
            'ping'
            ], env=_dcos_path()).decode()

    display.vvv("dcos edgelb: all prerequisites seem to be in order")

def install_dcos_edgelb_cli():
    """Install DC/OS edgelb CLI"""
    display.vvv("dcos edgelb: installing cli")

    cmd = [
        'dcos',
        'package',
        'install',
        'edgelb',
        '--cli',
        '--yes'
    ]
    display.vvv(subprocess.check_output(cmd, env=_dcos_path()).decode())

def get_pool_state(pool_id, instance_name):
    """Get the current state of a pool."""
    r = subprocess.check_output([
        'dcos',
        'edgelb',
        'list',
        '--name=' + instance_name,
        '--json'
        ], env=_dcos_path())
    pools = json.loads(r)

    display.vvv('looking for pool_id {}'.format(pool_id))

    state = 'absent'
    for p in pools:
        try:
            if pool_id in p['name']:
                state = 'present'
                display.vvv('found pool: {}'.format(pool_id))

        except KeyError:
         continue
    return state

def pool_create(pool_id, instance_name, options):
    """Create a pool"""
    display.vvv("DC/OS: edgelb create pool {}".format(pool_id))

    # create a temporary file for the options json file
    with tempfile.NamedTemporaryFile('w+') as f:
        json.dump(options, f)

        # force write the file to disk to make sure subcommand can read it
        f.flush()
        os.fsync(f)

        display.vvv(subprocess.check_output(
        ['cat', f.name]).decode())

        cmd = [
            'dcos',
            'edgelb',
            'create',
            '--name=' + instance_name,
            f.name
        ]
        run_command(cmd, 'update pool', stop_on_error=True)


def pool_update(pool_id, instance_name, options):
    """Update an pool"""
    display.vvv("DC/OS: Edgelb update pool {}".format(pool_id))

    # create a temporary file for the options json file
    with tempfile.NamedTemporaryFile('w+') as f:
        json.dump(options, f)

        # force write the file to disk to make sure subcommand can read it
        f.flush()
        os.fsync(f)

        display.vvv(subprocess.check_output(
        ['cat', f.name]).decode())

        cmd = [
            'dcos',
            'edgelb',
            'update',
            '--name=' + instance_name,
            f.name
        ]
        run_command(cmd, 'update pool', stop_on_error=True)

def pool_delete(pool_id, instance_name):
    """Delete a pool"""
    display.vvv("DC/OS: Edge-LB delete pool {}".format(pool_id))

    cmd = [
        'dcos',
        'edgelb',
        'delete',
        '--name=' + instance_name,
        pool_id,
    ]
    run_command(cmd, 'delete pool', stop_on_error=True)

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):

        result = super(ActionModule, self).run(tmp, task_vars)
        del tmp  # tmp no longer has any effect

        if self._play_context.check_mode:
            # in --check mode, always skip this module execution
            result['skipped'] = True
            result['msg'] = 'The dcos task does not support check mode'
            return result

        args = self._task.args
        state = args.get('state', 'present')

        instance_name = args.get('instance_name', 'edgelb')
        # ensure pool_id has no leading forward slash
        pool_id = args.get('pool_id', '').strip('/')

        options = args.get('options') or {}
        options['name']= pool_id

        ensure_dcos()
        ensure_dcos_edgelb(instance_name)

        current_state = get_pool_state(pool_id, instance_name)
        wanted_state = state

        if current_state == wanted_state:
            
            display.vvv(
                "edgelb pool {} already in desired state {}".format(pool_id, wanted_state))

            if wanted_state == "present":
                pool_update(pool_id, instance_name, options)

            result['changed'] = False
        else:
            display.vvv("edgelb pool {} not in desired state {}".format(pool_id, wanted_state))

            if wanted_state != 'absent':
                pool_create(pool_id, instance_name, options)
            else:
                pool_delete(pool_id, instance_name)

            result['changed'] = True

        return result
