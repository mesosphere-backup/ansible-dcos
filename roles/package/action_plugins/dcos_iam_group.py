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
from action_plugins.common import (
    ensure_dcos,
    ensure_dcos_security,
    run_command,
    _dcos_path
)

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

def get_group_state(gid):
    """Get the current state of a group."""

    r = subprocess.check_output([
        'dcos',
        'security',
        'org',
        'groups',
        'show',
        '--json'
        ],
        env=_dcos_path()
    )
    groups = json.loads(r)

    display.vvv('looking for gid {}'.format(gid))

    state = 'absent'
    for g in groups:
        try:
            if gid in g:
                state = 'present'
                display.vvv('found app: {}'.format(gid))

        except KeyError:
         continue
    return state

def group_create(gid, description):
    """Create a group"""
    display.vvv("DC/OS: IAM create group {}".format(gid))

    cmd = [
        'dcos',
        'security',
        'org',
        'groups',
        'create',
        '--description',
        '\'' + description + '\'',
        gid,
    ]
    run_command(cmd, 'create group', stop_on_error=True)

def group_update(gid, permissions):
    """Update group permissions"""
    display.vvv("DC/OS: IAM update group {}".format(gid))

    for p in permissions:
        display.vvv("Granting {} permission on {} to group {}".format(
            p['rid'], p['action'], gid))

        cmd = [
            'dcos',
            'security',
            'org',
            'groups',
            'grant',
            gid,
            p['rid'],
            p['action']
        ]
        run_command(cmd, 'update group', stop_on_error=False)

def group_delete(gid):
    """Delete a group"""
    display.vvv("DC/OS: IAM delete group {}".format(gid))

    cmd = [
        'dcos',
        'security',
        'org',
        'groups',
        'delete',
        gid,
    ]
    run_command(cmd, 'delete group', stop_on_error=True)

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
        gid = args.get('gid')
        description = args.get('description', 'Created by Ansible')
        permissions = args.get('permissions', [])
        wanted_state = args.get('state', 'present')

        if gid is None:
            raise AnsibleActionFail('gid cannot be empty for dcos_iam_group')

        ensure_dcos()
        ensure_dcos_security()

        current_state = get_group_state(gid)

        if current_state == wanted_state:
            
            display.vvv(
                "DC/OS IAM group {} already in desired state {}".format(gid, wanted_state))

            if wanted_state == "present":
                group_update(gid, permissions)

            result['changed'] = False
        else:
            display.vvv("DC/OS: IAM group {} not in desired state {}".format(gid, wanted_state))

            if wanted_state != 'absent':
                group_create(gid, description)
                group_update(gid, permissions)

            else:
                group_delete(gid)

            result['changed'] = True

        return result
