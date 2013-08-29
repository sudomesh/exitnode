exitnode
========

Configuration, script and instructions for exit nodes.

This is very much a work in progress.

Required packages so far: 

  dnsmasq
  squid3
  apache2 (though any webserver should do)
  postgresql (though any sql server should do)
  python2.7
  python-psycopg2
  
Assumed distro is debian.

= Setup instructions =

To /etc/postgresql/9.1/main/pg_hba.conf add this line:

  host    captive         captive         127.0.0.1/32            md5

Then:

/etc/init.d/postgresql restart

Then:

su postgres
psql
create database captive;
create table pass (id SERIAL, ipv4 varchar(16), ipv6 varchar(40), created timestamp DEFAULT current_timestamp);
create user captive with password '?fakingthecaptive?';
grant all privileges on database captive to captive;
grant all privileges on table pass to captive;
grant all privileges on sequence pass_id_seq to captive;

Then:

/etc/init.d/squid restart


TODO:

Set up tunneling between exit nodes and relay nodes (probably l2tp).

Automatically update firewall rules based on DNS every n minutes.

Remove hardcoded values in rewrite.py

Make the captive portal faker work with android and windows.

Test captive portal faker on more devices.
