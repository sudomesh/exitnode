exitnode
========

# Intro #

Our exit node is currently a single relay and exit server. All of the public traffic on peoplesopen.net access points is routed over an l2tp tunnel with tunneldigger through our exit server.
In this way, creating a new exit server would essentially create a new "mesh". For the time being, all sudomesh/peoplesopen.net traffic must travel over a single exit server in order to remain on the same network.

The l2tp kernel module is currently not compiled into Ubuntu, so we're using Debian.

We've set up a basic provisioning script, which is VERY MUCH A WORK IN PROGRESS, but should eventually take care of all of the steps required to set up and configure a new exit server.

# Installation #
On a debian distro, all you should need is git.

In a home dir:
`git clone `
cd exitnode

Then take a look at the provision.sh script. The first few lines are configs in order to set up the public IP of the exit server and the mesh IP. 

After editing these variables, you can run `./provision.sh <ARGUMENT1>` where ARGUMENT1 is the location of the exitnode repo folder.

eg:
`./provision.sh "/home/root/exitnode"`
