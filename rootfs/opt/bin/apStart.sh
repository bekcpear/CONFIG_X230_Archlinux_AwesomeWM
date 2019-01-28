#!/usr/bin/bash
#

case "$1" in
  start)
    true
    ;;
  stop)
    true
    ;;
  *)
    echo "usage: $0 start|stop"
    exit 1
    ;;
esac

##
# start

if [[ $1 == start ]]; then
  systemctl start openconnect@0
  systemctl start create_ap

  sleep 2
  firewall-cmd --reload

  ip rule del table main
  ip rule del table default
  ip rule add fwmark 0x1 table apoc
  ip rule add table main
  ip rule add table default
  ip route add default via 10.3.0.1 dev tun0 table apoc
  ip route add 10.3.0.0/24 dev tun0 table apoc
  ip route add 10.111.0.0/24 dev ap0 table apoc
  ip route del 10.3.0.0/24 dev tun0 table main
  ip route del 10.111.0.0/24 dev ap0 table main

  iptables -t mangle -I PREROUTING -s 10.111.0.0/24 -j MARK --set-mark 1
  iptables -t mangle -I PREROUTING -d 10.3.0.0/24 -j MARK --set-mark 1
  iptables -t nat -I POSTROUTING -o tun0 -j MASQUERADE
  iptables -I FORWARD -s 10.111.0.0/24 -j ACCEPT
  iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#  for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 0 > $f; done
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo 0 > /proc/sys/net/ipv4/route/flush
fi

##
# stop

if [[ $1 == stop ]]; then

  systemctl stop create_ap

  for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 2 > $f; done
  echo 0 > /proc/sys/net/ipv4/ip_forward
  ip route del default via 10.3.0.1 dev tun0 table apoc
  ip rule del fwmark 0x1 table apoc
  firewall-cmd --reload

  systemctl stop openconnect@0
fi

# refer:
#   https://unix.stackexchange.com/a/32406
#   https://unix.stackexchange.com/a/58947
#   http://lartc.org/howto/lartc.kernel.html
