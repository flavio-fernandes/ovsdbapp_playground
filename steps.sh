#!/bin/bash

set -o errexit

cd $(dirname $0)

./step0_ovn_setup.py
./step1_create_namespaces.sh
./step2_create_logical_ports.py
./step3_test.sh
./step4_remove_logical_ports.py
./step5_remove_namespaces.sh
