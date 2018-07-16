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

from action_plugins.dcos_secret import (
    get_secret_value,
    secret_delete
)
try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

def get_service_account_state(sid):
    """Get the current state of a service_account."""

    r = subprocess.check_output([
        'dcos',
        'security',
        'org',
        'service-accounts',
        'show',
        '--json'
        ],
        env=_dcos_path()
    )
    service_accounts = json.loads(r)

    display.vvv('looking for sid {}'.format(sid))

    state = 'absent'
    for g in service_accounts:
        try:
            if sid in g:
                state = 'present'
                display.vvv('found sid: {}'.format(sid))

        except KeyError:
         continue
    return state

def service_account_create(sid, secret_path, store, description):
    """Create a service_account"""
    display.vvv("DC/OS: IAM create service_account {}".format(sid))

    if get_secret_value(secret_path, store) is not None:
        secret_delete(secret_path, store)

    with tempfile.NamedTemporaryFile('w+') as f_private:
        with tempfile.NamedTemporaryFile('w+') as f_public:

            cmd = [
                'dcos',
                'security',
                'org',
                'service-accounts',
                'keypair',
                f_private.name, f_public.name
            ]
            run_command(cmd, 'create kepypairs', stop_on_error=True)

            display.vvv(subprocess.check_output(
                ['cat', f_private.name]).decode())
            display.vvv(subprocess.check_output(
                ['cat', f_public.name]).decode())

            cmd = [
                'dcos',
                'security',
                'org',
                'service-accounts',
                'create',
                sid,
                '--public-key',
                f_public.name,
                '--description',
                description
            ]
            run_command(cmd, 'create service account', stop_on_error=True)

            cmd = [
                'dcos',
                'security',
                'secrets',
                'create-sa-secret',
                '--store-id',
                store,
                '--strict',
                f_private.name,
                sid,
                secret_path
            ]
            run_command(cmd, 'create service secret', stop_on_error=True)

def service_account_update(sid, groups):
    """Update service_account groups"""
    display.vvv("DC/OS: IAM update service_account {}".format(sid))

    for g in groups:
        display.vvv("Assigning service_account {} to group {}".format(
            sid,g))

        cmd = [
            'dcos',
            'security',
            'org',
            'groups',
            'add_user',
            g,
            sid
        ]
        run_command(cmd, 'update service_account', stop_on_error=False)

def service_account_delete(sid):
    """Delete a service_account"""
    display.vvv("DC/OS: IAM delete service_account {}".format(sid))

    cmd = [
        'dcos',
        'security',
        'org',
        'service-accounts',
        'delete',
        sid,
    ]
    run_command(cmd, 'delete service_account', stop_on_error=True)

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
        sid = args.get('sid')
        description = args.get('description', 'Created by Ansible')
        secret_path = args.get('secret_path')
        store = args.get('store', 'default')
        groups = args.get('groups', [])
        wanted_state = args.get('state', 'present')

        if sid is None:
            raise AnsibleActionFail('sid cannot be empty for dcos_iam_service_account')

        if secret_path is None:
            raise AnsibleActionFail('secret_path cannot be empty for dcos_iam_service_account')

        ensure_dcos()
        ensure_dcos_security()

        current_state = get_service_account_state(sid)

        if current_state == wanted_state:
            
            display.vvv(
                "DC/OS IAM service_account {} already in desired state {}".format(sid, wanted_state))

            result['changed'] = False

            if wanted_state == "present":

                if get_secret_value(secret_path, store) is None:
                    service_account_delete(sid)
                    service_account_create(sid, secret_path, store, description)
                    result['changed'] = True

                service_account_update(sid, groups)

        else:
            display.vvv("DC/OS: IAM service_account {} not in desired state {}".format(sid, wanted_state))

            if wanted_state != 'absent':
                service_account_create(sid, secret_path, store, description)
                service_account_update(sid, groups)

            else:
                service_account_delete(sid)

            result['changed'] = True

        return result
