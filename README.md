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

## Testing Routing with Babeld Through Tunnel Digger

This assumes that you have an active and functioning tunnel on interface l2tp0 with ip 100.65.26.1 (see previous test).

Now that we have a functioning tunnel, we can test babeld routing as follows:

Step 1. install and build babeld using https://github.com/sudomesh/babeld
Please follow install instructions on said repository. Make sure you remove an existing babeld before installing this one.

Step 2. start babeld on l2tp0 
Execute ```sudo babeld l2tp0``` and keep running in a separate window.

Step 3. check routes
After running ```ip route``` you should see entries like:

```
100.64.0.42 via 100.64.0.42 dev l2tp0  proto babel onlink 
```

Step 4. ping the mesh routing ip
Now, execute ```ping 100.64.0.42``` and you should see something like:

```
$ ping 100.64.0.42
PING 100.64.0.42 (100.64.0.42) 56(84) bytes of data.
64 bytes from 100.64.0.42: icmp_seq=1 ttl=64 time=207 ms
64 bytes from 100.64.0.42: icmp_seq=2 ttl=64 time=204 ms
```

Step 5. now, stop the babeld process using ctrl-c

Step 6. repeat steps 3/4 and confirm that the routes are gone and the ping no longer succeeds.

PS If you'd like to see the traffic in the tunnel, you can run ```sudo tcpdump -i l2tp0``` . When running the ping, you should see ICMP ECHO messages and babeld "hello" and "hello ihu" (ihu = I hear you).

Step 7. route to internet

After restarting babeld (step 2), add a route for 8.8.8.8 via mesh router using ```sudo ip r add 8.8.8.8 via 100.64.0.42 dev l2tp0  proto babel onlink```.

Now, when pinging ```ping 8.8.8.8``` you should see the traffic going through the tunnel. As seen from the broker/server : 

```
04:12:49.900483 IP google-public-dns-a.google.com > 100.65.26.1: ICMP echo reply, id 2324, seq 49, length 64
04:12:50.777621 IP6 fe80::fc16:44ff:fe04:e0eb.6696 > ff02::1:6.6696: babel 2 (24) hello ihu
04:12:50.891593 IP 100.65.26.1 > google-public-dns-a.google.com: ICMP echo request, id 2324, seq 50, length 64
04:12:50.891873 IP google-public-dns-a.google.com > 100.65.26.1: ICMP echo reply, id 2324, seq 50, length 64
04:12:51.154965 IP6 fe80::9007:afff:fe6a:aa9.6696 > ff02::1:6.6696: babel 2 (24) hello ihu
04:12:54.767561 IP6 fe80::fc16:44ff:fe04:e0eb.6696 > ff02::1:6.6696: babel 2 (44) hello nh router-id update
04:12:55.697947 IP6 fe80::9007:afff:fe6a:aa9.6696 > ff02::1:6.6696: babel 2 (8) hello
04:12:58.646455 IP6 fe80::fc16:44ff:fe04:e0eb.6696 > ff02::1:6.6696: babel 2 (8) hello
04:12:59.443288 IP6 fe80::9007:afff:fe6a:aa9.6696 > ff02::1:6.6696: babel 2 (8) hello
04:13:02.167520 IP6 fe80::fc16:44ff:fe04:e0eb.6696 > ff02::1:6.6696: babel 2 (24) hello ihu
04:13:03.402486 IP6 fe80::9007:afff:fe6a:aa9.6696 > ff02::1:6.6696: babel 2 (156) hello ihu router-id update/prefix update/prefix nh update update up
```

## Configure Home Node to use exit node 

Now that you tested that the tunnel is working with babeld and able to (statically) route messages to 8.8.8.8 on the "big" internet, you can try and configuring a home node (see https://peoplesopen.net/walkthrough). 

To setup the new exit node, ssh into the home router ```ssh root@172.30.0.1``` after connecting to provide SSID.

Now edit the tunneldigger configuration by:

```vi /etc/config/tunneldigger```

and change the list address from ```list address '45.34.140.42:8942'``` to ```list address '[exit node ip]:8942'```.

For some reason, a default route on the home node to the exit node has to be manually added like so -

```ip route add default via 100.64.0.42 dev l2tp0  proto babel onlink table public```. This smells like a bug in which babeld doesn't install default proper default routes. 



Now, execute ```reboot now``` to apply new changes.
