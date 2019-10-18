#!/bin/bash

set -o xtrace

sudo ovs-vsctl del-port ns1
sudo ovs-vsctl del-port ns2
sudo ovs-vsctl del-port ns3
sudo ip netns delete ns1
sudo ip netns delete ns2
sudo ip netns delete ns3

