#!/bin/bash

hostlines=()
old_hostlines=()
host_file="/etc/squid3/hosts"
old_host_file="/etc/squid3/hosts.old"
squid_port=3128


# First clear old squid redirect iptables rules
while read -r line
do
    old_hostlines=("${old_hostlines[@]}" "${line}")
done < "$old_host_file"

for ip in "${old_hostlines[@]}"; do
    iptables -t nat -D PREROUTING -i bat0 -p tcp -d ${ip} --dport 80 -j REDIRECT --to-port 3128
done

echo "" > ${old_host_file}


# Now clear new-ish squid redirect iptables rules
while read -r new_line
do
    hostlines=("${hostlines[@]}" "${new_line}")
done < "$host_file"

for new_ip in "${hostlines[@]}"; do
    iptables -t nat -D PREROUTING -i bat0 -p tcp -d ${new_ip} --dport 80 -j REDIRECT --to-port 3128
done

echo "" > ${host_file}
