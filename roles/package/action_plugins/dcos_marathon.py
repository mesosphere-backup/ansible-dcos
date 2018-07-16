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

def get_app_state(app_id):
    """Get the current state of an app."""
    r = subprocess.check_output(['dcos', 'marathon', 'app', 'list', '--json' ], env=_dcos_path())
    apps = json.loads(r)

    display.vvv('looking for app_id {}'.format(app_id))

    state = 'absent'
    for a in apps:
        try:
            if app_id in a['id']:
                state = 'present'
                display.vvv('found app: {}'.format(app_id))

        except KeyError:
         continue
    return state

def app_create(app_id, options):
    """Deploy an app via Marathon"""
    display.vvv("DC/OS: Marathon create app {}".format(app_id))

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
            'marathon',
            'app',
            'add',
            f.name
        ]
        run_command(cmd, 'add app', stop_on_error=True)


def app_update(app_id, options):
    """Update an app via Marathon"""
    display.vvv("DC/OS: Marathon update app {}".format(app_id))

    # create a temporary file for the options json file
    with tempfile.NamedTemporaryFile('w+') as f:
        json.dump(options, f)

        # force write the file to disk to make sure subcommand can read it
        f.flush()
        os.fsync(f)

        cmd = [
            'dcos',
            'marathon',
            'app',
            'update',
            '--force',
            app_id
        ]

        from subprocess import Popen, PIPE

        p = Popen(cmd, env=_dcos_path(), stdin=PIPE, stdout=PIPE, stderr=PIPE)
        stdout, stderr = p.communicate(json.dumps(options))

        display.vvv("stdout {}".format(stdout))
        display.vvv("stderr {}".format(stderr))

def app_remove(app_id):
    """Remove an app via Marathon"""
    display.vvv("DC/OS: Marathon remove app {}".format(app_id))

    cmd = [
        'dcos',
        'marathon',
        'app',
        'remove',
        '/' + app_id,
    ]
    run_command(cmd, 'remove app', stop_on_error=True)

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

        # ensure app_id has a single leading forward slash
        app_id = '/' + args.get('app_id', '').strip('/')

        options = args.get('options') or {}
        options['id']= app_id

        ensure_dcos()

        current_state = get_app_state(app_id)
        wanted_state = state

        if current_state == wanted_state:
            
            display.vvv(
                "Marathon app {} already in desired state {}".format(app_id, wanted_state))

            if wanted_state == "present":
                app_update(app_id, options)

            result['changed'] = False
        else:
            display.vvv("Marathon app {} not in desired state {}".format(app_id, wanted_state))

            if wanted_state != 'absent':
                app_create(app_id, options)
            else:
                app_remove(app_id)

            result['changed'] = True

        return result
