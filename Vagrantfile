# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "puppetlabs/centos-7.0-64-puppet"
  config.vm.box_version = " 1.0.1 "
  config.vm.define :db1 do |db|
    db.vm.hostname = "db1"
    db.vm.network :private_network, ip: "192.168.56.101"
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.name = "db1"
    end
    db.vm.provision :puppet, :options => '--modulepath="/vagrant/puppet/modules":"/vagrant/puppet/roles"' do |puppet|
       puppet.manifests_path = "./puppet/manifests"
       puppet.manifest_file  = "app.pp"
    end
  end
  config.vm.define :db2 do |db|
    db.vm.hostname = "db2"
    db.vm.network :private_network, ip: "192.168.56.102"
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.name = "db2"
    end
    db.vm.provision :puppet, :options => '--modulepath="/vagrant/puppet/modules":"/vagrant/puppet/roles"' do |puppet|
       puppet.manifests_path = "./puppet/manifests"
       puppet.manifest_file  = "app.pp"
    end
  end
end
