# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">=1.7.0"


$bootstrap_ovn = <<SCRIPT

# Add repo for where we can get OVS packages
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
if [ ! -e /etc/yum.repos.d/delorean-deps.repo ] ; then
    curl -L http://trunk.rdoproject.org/centos8/delorean-deps.repo | sudo tee /etc/yum.repos.d/delorean-deps.repo
fi

dnf install -y libibverbs
dnf install -y openvswitch openvswitch-ovn-host

for n in openvswitch ovn-controller ; do
    systemctl enable --now $n
    systemctl status $n
done

SCRIPT

$bootstrap_ovn_central = <<SCRIPT

dnf install -y openvswitch-ovn-central
systemctl enable --now ovn-northd

SCRIPT

$bootstrap_python = <<SCRIPT
ln -s /vagrant/scripts ${HOME}/scripts ||:

sudo dnf install -y python3 python3-pip
sudo alternatives --set python $(which python3)
sudo alternatives --set pip $(which pip3)

cd
[ -e ./.env/bin/activate ] || {
    echo '[ -e "${HOME}/.env/bin/activate" ] && source ${HOME}/.env/bin/activate' >> .bashrc
    python -m venv --copies .env && source ./.env/bin/activate
}
pip install --upgrade pip
#  pip install ovsdbapp
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos/8"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"
  config.vm.provision "bootstrap_ovn", type: "shell", inline: $bootstrap_ovn
  config.vm.provision "bootstrap_python", type: "shell", inline: $bootstrap_python, privileged: false

  config.vm.define "ovn0", primary: true, autostart: true do |ovn0|
    ovn0.vm.hostname = "ovn0"
    ovn0.vm.network "private_network", ip: "192.168.122.100",
                    :mac => 'decaff000064'
    ovn0.vm.provision "bootstrap_ovn_central", type: "shell", inline: $bootstrap_ovn_central
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      vb.customize ["guestproperty", "set", :id,
                    "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
    end
  end
  config.vm.define "ovn1", primary: false, autostart: true do |ovn1|
    ovn1.vm.hostname = "ovn1"
    ovn1.vm.network "private_network", ip: "192.168.122.101",
                    :mac => 'decaff000065'
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      vb.customize ["guestproperty", "set", :id,
                    "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
    end
  end
  config.vm.define "ovn2", primary: false, autostart: true do |ovn2|
    ovn2.vm.hostname = "ovn2"
    ovn2.vm.network "private_network", ip: "192.168.122.102",
                    :mac => 'decaff000066'
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      vb.customize ["guestproperty", "set", :id,
                    "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
    end
  end
  config.vm.provider 'libvirt' do |lb|
      lb.nested = true
      lb.suspend_mode = 'managedsave'
      #lb.storage_pool_name = 'images'
  end
end
