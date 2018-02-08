exitnode
========

# Intro #

Our exit node is currently a single relay and exit server. All of the public traffic on peoplesopen.net access points is routed over an l2tp tunnel with tunneldigger through our exit server.
In this way, creating a new exit server would essentially create a new "mesh". For the time being, all sudomesh/peoplesopen.net traffic must travel over a single exit server in order to remain on the same network.

__work in progress__

# Installation #

(is being tested on digitalocean ubuntu 16.04)

## Ubuntu ##

Create a server (e.g., digitalocean on some other place) with Ubuntu 16.04 on it. 

Clone this repository on your local machine.

Now run: 

```
ssh root@[ip exit node] 'bash -s' < create_exitnode.sh [ip exit node]
```

and if your ethernet interface isn't eth0 then you need to edit the `except-interface=` line in dnsmasq.conf

## Other Linux ##

Not yet supported. Accepting pull requests!
