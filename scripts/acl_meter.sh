#!/bin/bash

set -o xtrace
set -o errexit

# Add a repo for where we can get OVS 2.6 packages
if [ ! -e /etc/yum.repos.d/delorean-deps.repo ] ; then
    curl -L http://trunk.rdoproject.org/centos7/delorean-deps.repo | sudo tee /etc/yum.repos.d/delorean-deps.repo
fi
sudo dnf install -y libibverbs
sudo dnf install -y openvswitch openvswitch-ovn-central openvswitch-ovn-host
for n in openvswitch ovn-controller ovn-northd ; do
    sudo systemctl enable --now $n ||:
    #systemctl status $n
done
sudo ovs-vsctl set open . external-ids:ovn-remote=unix:/var/run/ovn/ovnsb_db.sock
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=127.0.0.1

sudo ovn-nbctl ls-add sw0
sudo ovn-nbctl lsp-add sw0 sw0-port1
sudo ovn-nbctl lsp-set-addresses sw0-port1 "50:54:00:00:00:01 192.168.0.11"
sudo ovn-nbctl lsp-add sw0 sw0-port2
sudo ovn-nbctl lsp-set-addresses sw0-port2 "50:54:00:00:00:02 192.168.0.12"
sudo ovn-nbctl lsp-add sw0 sw0-port3
sudo ovn-nbctl lsp-set-addresses sw0-port3 "50:54:00:00:00:03 192.168.0.13"

add_phys_port() {
    name=$1 ; mac=$2 ; ip=$3 ; mask=$4 ; iface_id=$5
    sudo ip netns add $name
    sudo ovs-vsctl add-port br-int $name -- set interface $name type=internal
    sudo ip link set $name netns $name
    sudo ip netns exec $name ip link set lo up
    sudo ip netns exec $name ip link set $name address $mac
    sudo ip netns exec $name ip addr add $ip/$mask dev $name
    sudo ip netns exec $name ip link set $name up
    sudo ovs-vsctl set Interface $name external_ids:iface-id=$iface_id
}

add_phys_port ns1 50:54:00:00:00:01 192.168.0.11 24 sw0-port1
add_phys_port ns2 50:54:00:00:00:02 192.168.0.12 24 sw0-port2
add_phys_port ns3 50:54:00:00:00:03 192.168.0.13 24 sw0-port3

sudo ovn-nbctl --wait=hv acl-add sw0 to-lport 1002 'outport == "sw0-port1" && ip4.src == 192.168.0.12' allow
sudo ovn-nbctl --wait=hv acl-add sw0 to-lport 1002 'outport == "sw0-port1" && ip4.src == 192.168.0.13' allow

ACL_PRT2=$(sudo ovn-nbctl --bare --column _uuid,match find acl | grep -B1 '192.168.0.12' | head -1)
ACL_PRT3=$(sudo ovn-nbctl --bare --column _uuid,match find acl | grep -B1 '192.168.0.13' | head -1)

sudo ovn-nbctl meter-add meter_me drop 1 pktps
sudo ovn-nbctl set acl ${ACL_PRT2} log=true severity=alert meter=meter_me name=important_thing
sudo ovn-nbctl set acl ${ACL_PRT3} log=true severity=info  meter=meter_me name=noisy_neighbor

# If you are using a build with changes
# https://patchwork.ozlabs.org/project/ovn/patch/20201103221834.25541-2-flavio@flaviof.com/
# This will make the meters work in a way that noisy_neighbor will not affect important_thing
sudo ovn-nbctl set nb_global . options:acl_shared_log_meters="meter_me"

# start noisy neighbor
sudo nohup ip netns exec ns3 ping -q -i 0.1 192.168.0.11 & echo .
sleep 2.3

# start important thing, which is not lucky enough to get a single acl log :(
sudo nohup ip netns exec ns2 ping -q -i 2.2 192.168.0.11 & echo .
sleep 3

# We can follow all the action by doing this in a separate shell
echo 'look at:   sudo tail -F /var/log/ovn/ovn-controller.log | grep name'
# sleep 20

sudo grep -q noisy_neighbor /var/log/ovn/ovn-controller.log || {
    echo 'ERROR: did not locate noisy_neighbor in logs for acl' >&2
    exit 1
}

sudo grep -q important_thing /var/log/ovn/ovn-controller.log && {
    echo 'WOW: located important_thing in logs for acl. You made ACLs fair?' >&2
    exit 2
}

sudo pkill --oldest ping  ; # stop noisy ping neighbor
sleep 3

sudo grep -q important_thing /var/log/ovn/ovn-controller.log || {
    echo 'ERROR: did not locate important_thing in logs for acl' >&2
    exit 3
}

#sudo pkill ping
echo 'This concludes our noisy neighbor demo. Thank you for watching. ;)'
exit 0
