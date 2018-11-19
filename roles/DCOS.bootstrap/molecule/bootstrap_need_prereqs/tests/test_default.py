import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')

def test_docker_running_and_enabled(host):
    docker = host.service("docker")
    assert docker.is_running
    assert docker.is_enabled

def test_docker_serves_bootstrap_files(host):
    # TODO: get nodes config in here somehow and make uri dynamic
    cmd = host.run(
        "curl -I http://localhost:8080/1.12.0-beta1/genconf/serve/bootstrap.latest")
    assert cmd.rc == 0
    assert '200 OK' in cmd.stdout
