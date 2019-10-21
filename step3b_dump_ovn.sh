#!/bin/bash

set -o errexit
#set -o xtrace

abbrev() { a='[0-9a-fA-F]' b=$a$a c=$b$b; sed "s/$b-$c-$c-$c-$c$c$c//g"; }

msg() {
    echo
    echo '-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-'
    echo
    echo '****  ' $@ '  ****'
    echo
}


msg 'ovn-nbctl show'
sudo ovn-nbctl show | abbrev

msg 'ovn-nbctl acl-list sw0'
sudo ovn-nbctl acl-list sw0

msg 'ovn-sbctl show'
sudo ovn-sbctl show | abbrev


RTR_SUBNET1_MAC=$(sudo ovn-nbctl --bare --columns=mac find logical_router_port networks=192.168.0.1/24)
SW0_PORT1_MAC='50:54:00:00:00:01'
TRACE_ARG='inport == "sw0-port1" && eth.src == '${SW0_PORT1_MAC}' && eth.dst == '${RTR_SUBNET1_MAC}'
    && ip4.src == 192.168.0.2 && ip4.dst == 11.0.0.2 && ip.ttl == 64 && icmp4.type == 8'

msg "ovn-trace from sw0-port1 to sw1-port1"
sudo ovn-trace sw0 "${TRACE_ARG}" | abbrev

