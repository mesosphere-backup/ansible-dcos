# Generate networking configuration
system("
    if [ #{ARGV[0]} = 'up' ]; then
cat <<EOF > group_vars/all/networking.yaml
---
# (internal) IP Address of the Workstation
workstation_ip: 192.168.33.10

# (internal) IP Addresses for the Master Nodes
master_list: |
  - 192.168.33.11

# DNS Resolvers
resolvers: |
  - 8.8.4.4
  - 8.8.8.8

# DNS Search Domain
dns_search: None
EOF
    fi
")

# Define hosts file
ANSIBLE_GROUPS = {
  "workstations" => ["ws1"],
  "masters" => ["m1"],
  "agents" => ["a1"],
  "common:children" => ["workstations", "masters", "agents"]
}

# Create machines
Vagrant.configure(2) do |config|

    config.vm.box = "centos/7"

    config.vm.define "ws1" do |ws1|
        ws1.vm.network "private_network", ip: "192.168.33.10"
        ws1.vm.hostname = "ws1"
        ws1.vm.provision "ansible" do |ansible|
            ansible.playbook = "install.yml"
            ansible.groups = ANSIBLE_GROUPS
        end
    end

    config.vm.define "m1" do |m1|
        m1.vm.network "private_network", ip: "192.168.33.11"
        m1.vm.hostname = "m1"
        m1.vm.provision "ansible" do |ansible|
            ansible.playbook = "install.yml"
            ansible.groups = ANSIBLE_GROUPS
        end
    end

    config.vm.define "a1" do |a1|
        a1.vm.network "private_network", ip: "192.168.33.12"
        a1.vm.hostname = "a1"
        config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", "2048"]
          vb.customize ["modifyvm", :id, "--cpus", "2"]
        end
        a1.vm.provision "ansible" do |ansible|
            ansible.playbook = "install.yml"
            ansible.groups = ANSIBLE_GROUPS
        end
    end

end
