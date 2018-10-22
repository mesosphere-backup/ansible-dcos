import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_install_file(host):
    f = host.file('/opt/dcos-install/2e05da6b45f9f0e486de4d65404a0081099861c8/genconf/serve/dcos_install.sh')
    assert f.exists


def test_upgrade_file(host):
    f = host.file('/opt/dcos-install/2e05da6b45f9f0e486de4d65404a0081099861c8/genconf/serve/upgrade_from_1.10.4/latest/dcos_node_upgrade.sh')
    assert f.exists
