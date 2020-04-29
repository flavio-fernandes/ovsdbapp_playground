#!/bin/bash

set -o errexit

add_phys_port() {
    name=$1
    mac=$2
    ip=$3
    mask=$4
    gw=$5
    iface_id=$6
    sudo ip netns add $name
    sudo ovs-vsctl add-port br-int $name -- set interface $name type=internal
    sudo ip link set $name netns $name 
    sudo ip netns exec $name ip link set lo up
    sudo ip netns exec $name ip link set $name address $mac
    sudo ip netns exec $name ip addr add $ip/$mask dev $name 
    sudo ip netns exec $name ip link set $name up
    sudo ip netns exec $name ip route add default via $gw
    sudo ovs-vsctl set Interface $name external_ids:iface-id=$iface_id
}

sudo ovs-vsctl --may-exist add-br br-int
add_phys_port ns1 50:54:00:00:00:01 192.168.0.2 24 192.168.0.1 sw0-port1
add_phys_port ns2 50:54:00:00:00:02 192.168.0.3 24 192.168.0.1 sw0-port2
add_phys_port ns3 50:54:00:00:00:03 11.0.0.2 24 11.0.0.1 sw1-port1

echo ok
