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

def get_current_version(package, app_id):
    """Get the current version of an installed package."""
    r = subprocess.check_output(['dcos', 'package', 'list', '--json', '--app-id='+app_id ], env=_dcos_path())
    packages = json.loads(r)

    display.vvv('looking for package {} app_id {}'.format(package, app_id))

    v = None
    for p in packages:
        try:
            if p['name'] == package and '/' + app_id in p['apps']:
                v = p['version']
        except KeyError:
         continue
    display.vvv('{} current version: {}'.format(package, v))
    return v


def get_wanted_version(version, state):
    if state == 'absent':
        return None
    return version

def install_package(package, version, options):
    """Install a Universe package on DC/OS."""
    display.vvv("DC/OS: installing package {} version {}".format(
        package, version))

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
            'package',
            'install',
            package,
            '--yes',
            '--package-version',
            version,
            '--options',
            f.name
        ]
        run_command(cmd, 'install package', stop_on_error=True)

def update_package(package, app_id, version, options):
    """Update a Universe package on DC/OS."""
    display.vvv("DC/OS: updating package {} version {}".format(
        package, version))

    app_remove(app_id)
    time.sleep(20)
    while get_current_version(package, app_id) is not None:
        time.sleep(1)

    install_package(package, version, options)

def uninstall_package(package, app_id):
    display.vvv("DC/OS: uninstalling package {}".format(package))

    cmd = [
        'dcos',
        'package',
        'uninstall',
        package,
        '--yes',
        '--app',
        '--app-id',
        '/' + app_id,
    ]
    run_command(cmd, 'uninstall package', stop_on_error=True)

def app_remove(app_id):
    display.vvv("DC/OS: remove app {}".format(app_id))

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
        package_name = args.get('name', None)
        package_version = args.get('version', None)
        state = args.get('state', 'present')

        # ensure app_id has no leading or trailing /
        app_id = args.get('app_id', package_name).strip('/')

        options = args.get('options') or {}
        try:
            options['service']['name']= app_id
        except KeyError:
            options['service'] = {'name': app_id }

        ensure_dcos()

        current_version = get_current_version(package_name, app_id)
        wanted_version = get_wanted_version(package_version, state)

        if current_version == wanted_version:
            display.vvv(
                "Package {} already in desired state".format(package_name))
            
            if state == "present":
                update_package(package_name, app_id, wanted_version, options)

            result['changed'] = False
        else:
            display.vvv("Package {} not in desired state".format(package_name))
            if wanted_version is not None:
                if current_version is not None:
                    update_package(package_name, app_id, wanted_version, options)
                else:
                    install_package(package_name, wanted_version, options)
            else:
                uninstall_package(package_name, app_id)

            result['changed'] = True

        return result
