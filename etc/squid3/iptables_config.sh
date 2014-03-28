#!/bin/bash

# A script for updating the iptables rules 
# it will look in /etc/squid3/hosts and add a 
# splash page redirect for every ip entry


new_hostlines=()
old_hostlines=()
new_host_file="/etc/squid3/hosts"
old_host_file="/etc/squid3/hosts.old"
squid_port=3128


# First clear old squid redirect iptables rules
while read -r old_line
do
    old_hostlines=("${old_hostlines[@]}" "${old_line}")
done < "$old_host_file"

for old_ip in "${old_hostlines[@]}"; do
    iptables -t nat -D PREROUTING -i bat0 -p tcp -d ${old_ip} --dport 80 -j REDIRECT --to-port 3128
done


# Now add new squid redirect iptables rules
while read -r new_line
do
    new_hostlines=("${new_hostlines[@]}" "${new_line}")
done < "$new_host_file"

for new_ip in "${new_hostlines[@]}"; do
    iptables -t nat -A PREROUTING -i bat0 -p tcp -d ${new_ip} --dport 80 -j REDIRECT --to-port 3128
done
