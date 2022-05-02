# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  
  # K3s Master Server
  config.vm.define "k3s1" do |node|
  
    node.vm.box               = "generic/ubuntu2004"
    node.vm.box_check_update  = false
    node.vm.box_version       = "3.3.0"
    node.vm.hostname          = "k3s1"

    node.vm.network "private_network", ip: "192.168.56.101"
  
    node.vm.provider :virtualbox do |v|
      v.name    = "k3s1"
      v.memory  = 8192
      v.cpus    = 2
    end

    node.vm.provision "shell", path: "bootstrap_kmaster.sh"
  
  end

  # K3s Worker Nodes
  NodeCount = 2

  (1..NodeCount).each do |i|

    config.vm.define "k3s#{i+1}" do |node|

      node.vm.box               = "generic/ubuntu2004"
      node.vm.box_check_update  = false
      node.vm.box_version       = "3.3.0"
      node.vm.hostname          = "k3s#{i+1}"

      node.vm.network "private_network", ip: "192.168.56.10#{i+1}"

      node.vm.provider :virtualbox do |v|
        v.name    = "k3s#{i+1}"
        v.memory  = 8192
        v.cpus    = 2
      end

      node.vm.provision "shell", path: "bootstrap_kworker.sh"

    end

  end

end
