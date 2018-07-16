"""
Action plugin to configure a DC/OS cluster.
Uses the Ansible host to connect directly to DC/OS.
"""

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import base64
import json
import subprocess
import time
import os
import sys

try:
    from urllib.parse import urlparse
except ImportError:
    from urlparse import urlparse

from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleActionFail

# to prevent duplicating code, make sure we can import common stuff
sys.path.append(os.getcwd())
sys.path.append(os.getcwd() + '/roles/package/')
from action_plugins.common import ensure_dcos, run_command, _dcos_path

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()

DCOS_CONNECT_FLAGS = ['insecure', 'no_check']
DCOS_AUTH_OPTS = [
    'username',
    'password',
    'password_env',
    'password_file',
    'provider',
    'private_key',
]
DCOS_CONNECT_OPTS = DCOS_AUTH_OPTS + ['ca_certs']

def check_cluster(name=None, url=None):
    """Check whether cluster is already setup.

    :param url: url of the cluster
    :return: boolean whether cluster is already setup
    """

    if url is not None:
        fqdn = urlparse(url).netloc
    else:
        fqdn = None

    attached_cluster = None
    wanted_cluster = None

    clusters = subprocess.check_output(['dcos', 'cluster', 'list', '--json'], env=_dcos_path())
    for c in json.loads(clusters):
        if fqdn == urlparse(c['url']).netloc:
            wanted_cluster = c
        elif c['name'] == name:
            wanted_cluster = c
        if c['attached'] is True:
            attached_cluster = c

    display.vvv('wanted:\n{}\nattached:\n{}\n'.format(wanted_cluster,
                                                      attached_cluster))

    if wanted_cluster is None:
        return False
    elif wanted_cluster == attached_cluster:
        return True
    else:
        subprocess.check_call(
            ['dcos', 'cluster', 'attach', wanted_cluster['cluster_id']], env=_dcos_path())
        return True


def parse_connect_options(cluster_options=True, **kwargs):
    valid_opts = DCOS_CONNECT_OPTS if cluster_options else DCOS_AUTH_OPTS
    cli_args = []
    for k, v in kwargs.items():
        cli_k = '--' + k.replace('_', '-')
        if cluster_options and k in DCOS_CONNECT_FLAGS and v is True:
            cli_args.append(cli_k)
        if k in valid_opts:
            cli_args.extend([cli_k, v])
    return cli_args


def ensure_auth(**connect_args):
    valid = False
    r = run_command(['dcos', 'config', 'show', 'core.dcos_acs_token'])

    if r.returncode == 0:
        parts = r.stdout.read().decode().split('.')
        info = json.loads(base64.b64decode(parts[1]))
        exp = int(info['exp'])
        limit = int(time.time()) + 5 * 60
        if exp > limit:
            valid = True

    if not valid:
        refresh_auth(**connect_args)


def refresh_auth(**kwargs):
    """Run the authentication command using the DC/OS CLI."""
    cli_args = parse_connect_options(False, **kwargs)
    return run_command(['dcos', 'auth', 'login'] + cli_args,
                       'refresh auth token', True)


def connect_cluster(**kwargs):
    """Connect to a DC/OS cluster by url"""

    changed = False
    url = kwargs.get('url')

    if not check_cluster(kwargs.get('name'), url):
        if url is None:
            raise AnsibleActionFail(
                'Not connected: you need to specify the cluster url')

        display.vvv('DC/OS cluster not setup, setting up')

        cli_args = parse_connect_options(**kwargs)
        display.vvv('args: {}'.format(cli_args))

        subprocess.check_call(['dcos', 'cluster', 'setup', url] + cli_args, env=_dcos_path())
        changed = True

    # ensure_auth(**kwargs)
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

        ensure_dcos()

        result['changed'] = connect_cluster(**args)
        return result