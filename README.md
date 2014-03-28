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
create user captive with password '?fakingthecaptive?';
create database captive;
\connect captive
create table pass (id SERIAL, ipv4 varchar(16), ipv6 varchar(40), created timestamp DEFAULT current_timestamp);
grant all privileges on database captive to captive;
grant all privileges on table pass to captive;
grant all privileges on sequence pass_id_seq to captive;

Then:

/etc/init.d/squid restart

In order to start the captive portal:

sudo /etc/init.d/captive_portal_redirect start

and to stop:

sudo /etc/init.d/captive_portal_redirect stop


