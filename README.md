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

## Testing Tunnel Digger

In order to check whether a client can establish a functioning tunnel using tunneldigger, assign an ip address to the l2tp0 interface on the client, and create a static route to the exit node address (default 100.64.0.42).

Recipe

step 1. create tunnel using tunneldigger client (see https://github.com/sudomesh/tunneldigger-lab)

step 2. assign some ip to tunneldigger client interface
Once the tunnel has been establish, an interface l2tp0 should appear when listing interfaces using ```ip addr```. To assign an ip to that interface, do something like ```sudo ip addr add 100.65.26.1 dev l2tp0```. 
Now, your ```ip addr``` should include:

```
l2tp0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1446 qdisc pfifo_fast state UNKNOWN group default qlen 1000
    link/ether 62:cb:8a:c9:27:17 brd ff:ff:ff:ff:ff:ff
    inet 100.65.26.1/32 scope global l2tp0
    valid_lft forever preferred_lft forever
    inet6 fe80::60cb:8aff:fec9:2717/64 scope link 
    valid_lft forever preferred_lft forever
```

step 3. establish static route from client to tunneldigger broker

Now, for the client to route packets to the tunneldigger broker using the l2tp0 interface, install a route using:

```
sudo ip r add 100.64.0.42 dev l2tp0
```

step 4. establish static route from tunneldigger broker to client

After logging into the exitnode/tunneldigger broker, install a static route to the client using ```sudo ip r add 100.65.26.1 dev l2tp1001```, where l2tp1001 is the interface that is created when the client established the tunnel. This can be found using ```ip addr | grep l2```.

step 5. ping from client to broker

Now, on the client, ping the broker using

```
ping -I l2tp0 100.64.0.42
```

If all works well, and the tunnel is working as expected, you should see:

```
$ ping -I l2tp0 100.64.0.42
PING 100.64.0.42 (100.64.0.42) from 100.65.26.1 l2tp0: 56(84) bytes of data.
64 bytes from 100.64.0.42: icmp_seq=1 ttl=64 time=228 ms
64 bytes from 100.64.0.42: icmp_seq=2 ttl=64 time=214 ms
```

If you can ping the broker via the tunnel interface, tunneldigger is doing it's job.



