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

def get_secret_value(path, store):
    """Get the current value of a secret."""

    display.vvv('looking for secret {} '.format(path))

    value = None
    try:
        r = subprocess.check_output([
            'dcos',
            'security',
            'secrets',
            'get',
            '--store-id',
            store,
            '--json',
            path
            ],
            env=_dcos_path(),
            stderr=subprocess.STDOUT
        )
        value = json.loads(r)['value']
        display.vvv('secret {} has value {}'.format(path, value))
    except:
        value = None

    return value

def secret_create(path, value, store):
    """Create a secret"""

    display.vvv("DC/OS: create secret {} with {}".format(path, value))

    cmd = [
        'dcos',
        'security',
        'secrets',
        'create',
        '--store-id',
        store,
        '--value',
        value,
        path
    ]
    run_command(cmd, 'create secret', stop_on_error=True)

def secret_update(path, value, store):
    """Update a secret"""

    display.vvv("DC/OS: update secret {} with {}".format(path, value))

    cmd = [
        'dcos',
        'security',
        'secrets',
        'update',
        '--store-id',
        store,
        '--value',
        value,
        path
    ]
    run_command(cmd, 'update secret', stop_on_error=True)

def secret_delete(path, store):
    """Delete a secret"""

    display.vvv("DC/OS: delete secret {}".format(path))

    cmd = [
        'dcos',
        'security',
        'secrets',
        'delete',
        '--store-id',
        store,
        path
    ]
    run_command(cmd, 'delete secret', stop_on_error=True)

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
        path = args.get('path')
        if path is None:
            raise AnsibleActionFail('path cannot be empty for dcos_secret')
        store = args.get('store', 'default')
        value = args.get('value')
        wanted_state = args.get('state', 'present')

        ensure_dcos()
        ensure_dcos_security()

        current_value = get_secret_value(path, store)

        current_state = 'present' if current_value is not None else 'absent'

        if current_state == wanted_state:
            
            display.vvv(
                "DC/OS Secret {} already in desired state {}".format(path, wanted_state))
            result['changed'] = False

            if wanted_state == "present" and current_value != value:
                secret_update(path, value, store)
                result['changed'] = True
                result['msg'] = "Secret {} was updated".format(path)

        else:
            display.vvv("DC/OS Secret {} not in desired state {}".format(path, wanted_state))

            if wanted_state != 'absent':
                secret_create(path, value, store)
                result['msg'] = "Secret {} was created".format(path)

            else:
                secret_delete(path, store)
                result['msg'] = "Secret {} was deleted".format(path)

            result['changed'] = True

        return result
