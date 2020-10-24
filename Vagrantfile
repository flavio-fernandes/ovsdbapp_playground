# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">=1.7.0"


$bootstrap_ovn = <<SCRIPT

# Add repo for where we can get OVS packages
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
if [ ! -e /etc/yum.repos.d/delorean-deps.repo ] ; then
    curl -L http://trunk.rdoproject.org/centos8/delorean-deps.repo | sudo tee /etc/yum.repos.d/delorean-deps.repo
fi

dnf install -y libibverbs
dnf install -y openvswitch openvswitch-ovn-central openvswitch-ovn-host

for n in openvswitch ovn-northd ovn-controller ; do
    systemctl enable --now $n
    systemctl status $n
done
SCRIPT

$bootstrap_python = <<SCRIPT
# ln -s /vagrant/scripts ${HOME}/scripts ||:
cp /vagrant/scripts/acl_meter.sh .
chmod 755 ./acl_meter.sh

sudo dnf install -y python3 python3-pip
sudo alternatives --set python $(which python3)
sudo alternatives --set pip $(which pip3)

cd
[ -e ./.env/bin/activate ] || {
    echo '[ -e "${HOME}/.env/bin/activate" ] && source ${HOME}/.env/bin/activate' >> .bashrc
    python -m venv --copies .env && source ./.env/bin/activate
}
pip install --upgrade pip
pip install ovsdbapp
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "centos-8" do |centos|
       centos.vm.hostname = "c8vm"
       centos.vm.box = "centos/8"
       # centos.vm.box = "centos/8_20200611"
       # centos.vm.box_url = "https://cloud.centos.org/centos/8/vagrant/x86_64/images/CentOS-8-Vagrant-8.2.2004-20200611.2.x86_64.vagrant-virtualbox.box"
       # centos.vm.box_url = "https://cloud.centos.org/centos/8/vagrant/x86_64/images/CentOS-8-Vagrant-8.2.2004-20200611.2.x86_64.vagrant-libvirt.box"
       # centos.vm.synced_folder "#{ENV['PWD']}", "/vagrant", sshfs_opts_append: "-o nonempty", disabled: false, type: "sshfs"
       centos.vm.synced_folder ".", "/vagrant", type: "rsync"
       centos.vm.provision "bootstrap_ovn", type: "shell", inline: $bootstrap_ovn
       centos.vm.provision "bootstrap_python", type: "shell", inline: $bootstrap_python, privileged: false
  end
end

