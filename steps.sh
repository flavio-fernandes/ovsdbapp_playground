#!/bin/bash

set -o errexit

cd $(dirname $0)

function wait_for_binding() {
    retries=0
    until [ $retries -ge 10 ]
    do
        binds=$(sudo ovn-sbctl -f csv -d bare --no-heading --columns="chassis" find port_binding logical_port\>\"sw\" | grep -c . ||:)
        [ $binds -gt 1 ] && break || echo 'waiting for port bind...'
        sleep 0.25
        ((retries++)) ||:
    done
}

./step0_ovn_setup.py
./step1_create_namespaces.sh
./step2_create_logical_ports.py

wait_for_binding

./step3_test.sh
./step4_remove_logical_ports.py
./step5_remove_namespaces.sh
