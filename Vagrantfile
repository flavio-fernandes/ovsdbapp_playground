# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">=1.7.0"


$bootstrap_ovn_from_src = <<SCRIPT
# loop to deal with flaky dnf
cnt=0
until [ $cnt -ge 3 ] ; do
   sudo dnf -y -vvv install \
       autoconf automake openssl-devel libtool \
       python3-devel python3-pip \
       desktop-file-utils graphviz rpmdevtools nc curl \
       wget checkpolicy selinux-policy-devel \
       libcap-ng-devel kernel-devel ethtool \
       lftp git libibverbs
   if [ "$?" -eq 0 ]; then break ; fi
   (( cnt++ ))
   >&2 echo "Sad panda: dnf failed ${cnt} times."
done
echo "search extra update built-in" | sudo tee /etc/depmod.d/search_path.conf
sudo pip3 install pyftpdlib tftpy twisted zope-interface sphinx

OVS_BRANCH=${OVS_BRANCH:-master}
OVN_BRANCH=${OVN_BRANCH:-$OVS_BRANCH}
OVS_SRCDIR=/home/vagrant/ovs
OVN_SRCDIR=/home/vagrant/ovn

if [ ! -d "$OVS_SRCDIR" ]; then
    echo "Building OVS branch $OVS_BRANCH in $OVS_SRCDIR"
    mkdir -p $OVS_SRCDIR
    git clone -b $OVS_BRANCH git://github.com/openvswitch/ovs.git $OVS_SRCDIR
    (cd $OVS_SRCDIR && ./boot.sh && ./configure)
    ## (cd $OVS_SRCDIR && make -j$(($(nproc) + 1)) V=0 && sudo make install)
    ## sudo ln -s /var /usr/local/var ||:

    sudo dnf -y --enablerepo=PowerTools install groff python3-sphinx
    sudo dnf -y install gcc-c++ unbound unbound-devel
    (cd $OVS_SRCDIR && make rpm-fedora RPMBUILD_OPT="--without check")
    sudo rpm -ivh $OVS_SRCDIR/rpm/rpmbuild/RPMS/x86_64/openvswitch-2*.el8.x86_64.rpm \
                  $OVS_SRCDIR/rpm/rpmbuild/RPMS/noarch/python3-openvswitch-*.el8.noarch.rpm
fi
if [ ! -d "$OVN_SRCDIR" ]; then
    echo "Building OVN branch $OVN_BRANCH in $OVN_SRCDIR"
    mkdir -p $OVN_SRCDIR
    git clone -b $OVN_BRANCH git://github.com/ovn-org/ovn.git $OVN_SRCDIR
    (cd $OVN_SRCDIR && ./boot.sh && ./configure --with-ovs-source=$OVS_SRCDIR)
    ## (cd $OVN_SRCDIR && make -j$(($(nproc) + 1)) V=0 && sudo make install)

    (cd $OVN_SRCDIR && make rpm-fedora)
    sudo rpm -ivh $OVN_SRCDIR/rpm/rpmbuild/RPMS/x86_64/{ovn-2*.el8.x86_64.rpm,ovn-central-2*.el8.x86_64.rpm,ovn-host-2*.el8.x86_64.rpm}
fi

for n in openvswitch ovn-northd ovn-controller ; do
    sudo systemctl enable --now $n
    sudo systemctl --no-pager status $n
done
SCRIPT

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
    systemctl --no-pager status $n
done
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
       # centos.vm.provision "bootstrap_ovn_from_src", type: "shell", inline: $bootstrap_ovn_from_src, privileged: false
       centos.vm.provision "bootstrap_ovn", type: "shell", inline: $bootstrap_ovn
       centos.vm.provision "bootstrap_python", type: "shell", inline: $bootstrap_python, privileged: false
  end
end

