#!/bin/bash

set -o errexit

sudo ovs-vsctl set open . external-ids:ovn-remote=unix:/var/run/openvswitch/ovnsb_db.sock
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=127.0.0.1

sudo /usr/share/openvswitch/scripts/ovn-ctl stop_northd
sudo rm -rf /etc/openvswitch/ovn{n,s}b_db.db
sudo /usr/share/openvswitch/scripts/ovn-ctl start_northd

sudo ovn-nbctl set-connection ptcp:6641:127.0.0.1
sudo ovn-nbctl get-connection

echo ok
