exitnode
========

# Intro #

Our exit node is currently a single relay and exit server. All of the public traffic on peoplesopen.net access points is routed over an l2tp tunnel with tunneldigger through our exit server.
In this way, creating a new exit server would essentially create a new "mesh". For the time being, all sudomesh/peoplesopen.net traffic must travel over a single exit server in order to remain on the same network.

The l2tp kernel module is currently not compiled into Ubuntu, so we're using Debian.

We've set up a basic provisioning script, which is VERY MUCH A WORK IN PROGRESS, but should eventually take care of all of the steps required to set up and configure a new exit server.

# Installation #

## Debian ##

### Quick Install ###

Installs with default configuration (not always desirable). Copy the file `quick_install.sh` to desired machine. Run as root:

    ./quick_install.sh

## Full Install ###

On a debian distro, all you should need is git. Run the following as root:

    apt-get install git

In a home dir:

    git clone https://github.com/sudomesh/exitnode.git
    cd exitnode

Then take a look at the provision.sh script. The first few lines are configs in order to set up the public IP of the exit server and the mesh IP.

### Provision Configuration Variables

`MESH_IP` sets IP address of exitnode on local network

    MESH_IP=10.42.0.99

`MESH_MTU` specifies [maximum transmission unit (MTU)](https://en.wikipedia.org/wiki/Maximum_transmission_unit), maximum for ethernet is 1500, default 1400.

    MESH_MTU=1400

`ETH_IF` sets the name of the ethernet interface to the external network (internet)

    ETH_IF=eth0

`PUBLIC_IP` sets IP address of exitnode on external network (internet)

    PUBLIC_IP="$(ifconfig | grep -A 1 "$ETH_IF" | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

### Run Provision Script

After editing these variables, you can run `./provision.sh <ARGUMENT1>` where ARGUMENT1 is the location of the exitnode repo folder. For example:

    ./provision.sh /home/root/exitnode

## Other Linux ##

Not yet supported. Accepting pull requests!
