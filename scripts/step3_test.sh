#!/bin/bash

msg() {
    echo $@
    echo
}

call_ping() {
     sudo ip netns exec $1 ping -c 1 -W 2 $2 > /dev/null
}

check_valid_ping() {
     call_ping $@ || { >&2 echo "ERROR: $1 failed to reach $2" && exit 1; }
}

check_invalid_ping() {
     call_ping $@ && >&2 echo "ERROR: $1 should not be able to reach $2" && exit 2
}

for dst in 192.168.0.1 192.168.0.3 11.0.0.1 11.0.0.2; do \
  check_valid_ping ns1 $dst
  msg "sw0-port1 (192.168.0.2) can ping $dst"
done


check_valid_ping ns2 192.168.0.1
msg "sw0-port2 (192.168.0.3) can ping logical router IP (192.168.0.1)"

check_valid_ping ns2 11.0.0.2
msg "sw0-port2 (192.168.0.3) can ping sw1-port1 (11.0.0.2)"

check_invalid_ping ns2 192.168.0.2
msg "sw0-port2 (192.168.0.3) should not be able to ping sw0-port1 (192.168.0.2)"

check_valid_ping ns3 11.0.0.1
msg "sw1-port1 (11.0.0.2) can ping logical router IP (11.0.0.1)"

check_valid_ping ns3 192.168.0.1
msg "sw1-port1 (11.0.0.2) can ping logical router IP (192.168.0.1)"

check_invalid_ping ns3 192.168.0.2
msg "sw1-port1 (11.0.0.2) should not be able to ping sw0-port1 (192.168.0.2)"

check_valid_ping ns3 192.168.0.3
msg "sw1-port1 (11.0.0.2) can ping sw0-port2 (192.168.0.3)"

msg 'All tests PASSED.'
exit 0
