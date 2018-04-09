"""
Action plugin to configure a DC/OS cluster.
Uses the Ansible host to connect directly to DC/OS.
"""

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json
import subprocess
import tempfile

from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleActionFail

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()


def _version(v):
    return tuple(map(int, v.split('.')))


def _ensure_dcos():
    """Check whether the dcos[cli] package is installed."""

    raw_version = ''
    r = subprocess.check_output(['dcos', '--version']).decode()
    for line in r.strip().split('\n'):
        display.vvv(line)
        k, v = line.split('=')
        if k == 'dcoscli.version':
            raw_version = v

    v = _version(raw_version)
    if v < (0, 5, 0):
        raise AnsibleActionFail(
            "DC/OS CLI 0.5.x is required, found {}".format(v))
    if v >= (0, 7, 0):
        raise AnsibleActionFail(
            "DC/OS CLI version > 0.7.x detected, may not work")
    display.vvv("dcos: all prerequisites seem to be in order")

def _ensure_dcos_security():
    """Check whether the dcos[cli] security extension is installed."""

    raw_version = ''
    try:
        r = subprocess.check_output(['dcos', 'security', '--version']).decode()
    except:
        display.vvv("dcos security: not installed")
        _install_dcos_security_cli()
        r = subprocess.check_output(['dcos', 'security', '--version']).decode()

    v = _version(r)
    if v < (1, 2, 0):
        raise AnsibleActionFail(
            "DC/OS Security CLI 1.2.x is required, found {}".format(v))

    display.vvv("dcos security: all prerequisites seem to be in order")

def _install_dcos_security_cli():
    """Install DC/OS Security CLI"""
    display.vvv("dcos security: installing cli")

    cmd = [
        'dcos', 'package', 'install', 'dcos-enterprise-cli', '--cli', '--yes'
    ]
    display.vvv(subprocess.check_output(cmd).decode())

def get_current_serviceaccount(name):
    """Get the current service account."""

    display.vvv('looking for service account {} '.format(name))

    sa_name = None
    try:
        r = subprocess.check_output(['dcos', 'security', 'org', 'service-accounts', 'show', '--json', name ])
        sa_name = name
    except:
        sa_name = None

    display.vvv('service account found: {}'.format(sa_name))
    return sa_name

def get_current_secret(secret):
    """Get the current secret of the service account."""

    display.vvv('looking for secret {} '.format(secret))

    secret_name = None
    try:
        r = subprocess.check_output(['dcos', 'security', 'secrets', 'get', '--json', secret ])
        secret_name = secret
    except:
        secret_name = None

    display.vvv('secret found: {}'.format(secret_name))
    return secret_name

def remove_serviceaccount(name):
    """Delete a Service Account on DC/OS."""
    display.vvv("DC/OS: remove service account {}".format(name))

    cmd = [
        'dcos',
        'security',
        'org',
        'service-accounts',
        'delete',
        name,
    ]
    display.vvv("command: " + ' '.join(cmd))
    display.vvv(subprocess.check_output(cmd).decode())

def create_serviceaccount(name, description, secret):
    """Create a Service Account on DC/OS."""

    current_secret = get_current_secret(secret)
    if current_secret is not None:
        display.vvv("DC/OS: clean up existing secret{}".format(secret))
        cmd = [
            'dcos', 'security', 'secrets', 'delete',
            secret
        ]
        display.vvv(subprocess.check_output(cmd).decode())

    display.vvv("DC/OS: create service account {}".format(name))
    with tempfile.NamedTemporaryFile('w+') as f_private:
        with tempfile.NamedTemporaryFile('w+') as f_public:
            cmd = [
                'dcos', 'security', 'org', 'service-accounts', 'keypair',
                f_private.name, f_public.name
            ]
            display.vvv("command: " + ' '.join(cmd))
            display.vvv('contents:')
            display.vvv(subprocess.check_output(cmd).decode())
            display.vvv(subprocess.check_output(['cat', f_private.name]).decode())
            display.vvv(subprocess.check_output(['cat', f_public.name]).decode())

            cmd = [
                'dcos', 'security', 'org', 'service-accounts', 'create',
                '-p', f_public.name,
                '-d', description,
                name
            ]
            display.vvv(subprocess.check_output(cmd).decode())

            cmd = [
                'dcos', 'security', 'secrets', 'create-sa-secret', '--strict',
                f_private.name,
                name,
                secret
            ]
            display.vvv(subprocess.check_output(cmd).decode())

def add_to_group(name, group):
    display.vvv("DC/OS: add service account {} to group {}".format(name, group))

    changed = False
    if group is not None:
        cmd = [
            'dcos',
            'security',
            'org',
            'groups',
            'add_user',
            group,
            name
        ]
        display.vvv("command: " + ' '.join(cmd))
        try:
            display.vvv(subprocess.check_output(cmd))
            changed = True
        except:
            changed = False

    return changed

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
        name = args.get('name', None)
        description = args.get('description', name)
        secret = args.get('secret', name + '/secret')
        group = args.get('group', None)
        state = args.get('state', 'present')

        _ensure_dcos()
        _ensure_dcos_security()

        current_serviceaccount = get_current_serviceaccount(name)

        if current_serviceaccount is not None and state == 'present':

            result['changed'] = False

            current_secret = get_current_secret(secret)
            if current_secret is None:
                remove_serviceaccount(name)
                create_serviceaccount(name, description, secret)
                result['changed'] = True

            if add_to_group(name, group):
                    result['changed'] = True

        elif current_serviceaccount is None and state == 'present':

            create_serviceaccount(name, description, secret)
            add_to_group(name, group)
            result['changed'] = True

        elif current_serviceaccount is not None and state == 'absent':
            remove_serviceaccount(name)
            result['changed'] = True

        else:
            display.vvv(
                "DC/OS: Service Account {} already in desired state".format(name))
            result['changed'] = False

        return result
