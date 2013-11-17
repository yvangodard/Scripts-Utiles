#! /bin/bash

/sbin/iptables -N CLEANUP
/sbin/iptables -A CLEANUP -p udp -m udp --dport 67 -j DROP
/sbin/iptables -A INPUT -j CLEANUP
/sbin/iptables -A INPUT -j LOG

exit 0