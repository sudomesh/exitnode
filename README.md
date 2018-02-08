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

Expected output should be something like:

```
Get:1 http://security.ubuntu.com/ubuntu xenial-security InRelease [102 kB]
Hit:2 http://ams2.mirrors.digitalocean.com/ubuntu xenial InRelease
Get:3 http://security.ubuntu.com/ubuntu xenial-security/main Sources [108 kB]
Get:5 http://security.ubuntu.com/ubuntu xenial-security/restricted Sources [2,116 B]
[...]
Cloning into '/opt/exitnode'...
tunneldigger.service is not a native service, redirecting to systemd-sysv-install
Executing /lib/systemd/systemd-sysv-install enable tunneldigger
babeld.service is not a native service, redirecting to systemd-sysv-install
Executing /lib/systemd/systemd-sysv-install enable babeld
```

# Testing

TODO outlines procedures on how to check whether the exit node is functioning properly. 


