# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "puppetlabs/centos-7.0-64-puppet"
  config.vm.box_version = " 1.0.1 "
  config.vm.define :db1 do |db|
    db.vm.hostname = "db-a"
    db.vm.network :private_network, ip: "192.168.56.1"
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.name = "db-a"
    end
    db.vm.provision :puppet, :options => '--modulepath="/vagrant/puppet/modules":"/vagrant/puppet/roles"' do |puppet|
       puppet.manifests_path = "./puppet/manifests"
       puppet.manifest_file  = "app.pp"
    end
  end
  config.vm.define :db2 do |db|
    db.vm.hostname = "db-b"
    db.vm.network :private_network, ip: "192.168.56.2"
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.name = "db-b"
    end
    db.vm.provision :puppet, :options => '--modulepath="/vagrant/puppet/modules":"/vagrant/puppet/roles"' do |puppet|
       puppet.manifests_path = "./puppet/manifests"
       puppet.manifest_file  = "app.pp"
    end
  end
end
