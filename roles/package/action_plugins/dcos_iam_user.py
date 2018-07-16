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

def get_user_state(uid):
    """Get the current state of a user."""

    r = subprocess.check_output([
        'dcos',
        'security',
        'org',
        'users',
        'show',
        '--json'
        ],
        env=_dcos_path()
    )
    users = json.loads(r)

    display.vvv('looking for uid {}'.format(uid))

    state = 'absent'
    for g in users:
        try:
            if uid in g:
                state = 'present'
                display.vvv('found uid: {}'.format(uid))

        except KeyError:
         continue
    return state

def user_create(uid, password, description):
    """Create a user"""
    display.vvv("DC/OS: IAM create user {}".format(uid))

    cmd = [
        'dcos',
        'security',
        'org',
        'users',
        'create',
        uid,
        '--description',
        description,
        '--password',
        password
    ]
    run_command(cmd, 'create user', stop_on_error=True)

def user_update(uid, groups):
    """Update user groups"""
    display.vvv("DC/OS: IAM update user {}".format(uid))

    for g in groups:
        display.vvv("Assigning user {} to group {}".format(
            uid,g))

        cmd = [
            'dcos',
            'security',
            'org',
            'groups',
            'add_user',
            g,
            uid
        ]
        run_command(cmd, 'update user', stop_on_error=False)

def user_delete(uid):
    """Delete a user"""
    display.vvv("DC/OS: IAM delete user {}".format(uid))

    cmd = [
        'dcos',
        'security',
        'org',
        'users',
        'delete',
        uid,
    ]
    run_command(cmd, 'delete user', stop_on_error=True)

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
        uid = args.get('uid')
        description = args.get('description', 'Created by Ansible')
        password = args.get('password')
        groups = args.get('groups', [])
        wanted_state = args.get('state', 'present')

        if uid is None:
            raise AnsibleActionFail('uid cannot be empty for dcos_iam_user')

        if password is None:
            raise AnsibleActionFail('password cannot be empty for dcos_iam_user')

        ensure_dcos()
        ensure_dcos_security()

        current_state = get_user_state(uid)

        if current_state == wanted_state:
            
            display.vvv(
                "DC/OS IAM user {} already in desired state {}".format(uid, wanted_state))

            if wanted_state == "present":
                user_update(uid, groups)

            result['changed'] = False
        else:
            display.vvv("DC/OS: IAM user {} not in desired state {}".format(uid, wanted_state))

            if wanted_state != 'absent':
                user_create(uid, password, description)
                user_update(uid, groups)

            else:
                user_delete(uid)

            result['changed'] = True

        return result
