#!/bin/sh

MESH_IP=10.42.0.99
MESH_MTU=1400
ETH_IF=eth0
PUBLIC_IP="$(ifconfig | grep -A 1 "$ETH_IF" | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)" 

if [ "$#" -le 0 ]
then
  SRC_DIR="/vagrant/"
else
  SRC_DIR="$1"
fi

apt-get update && apt-get install -y --force-yes \
  nginx \
  build-essential \
  ca-certificates \
  curl \
  git \
  libssl-dev \
  libxslt1-dev \
  module-init-tools \
  batctl \
  bridge-utils \
  openssh-server \
  openssl \
  perl \
  dnsmasq \
  squid3 \
  postgresql \
  procps \
  procps \
  python-psycopg2 \
  python-software-properties \
  software-properties-common \
  python \
  python-dev \
  python-pip \
  iproute \
  libnetfilter-conntrack3 \
  libevent-dev \
  ebtables \
  vim \
  tmux

REQUIRED_MODULES="nf_conntrack_netlink nf_conntrack nfnetlink l2tp_netlink l2tp_core l2tp_eth batman_adv"

for module in $REQUIRED_MODULES
do
  if grep -q "$module" /etc/modules
  then
    echo "$module already in /etc/modules"
  else
    echo "\n$module" >> /etc/modules
  fi
  modprobe $module
done

# All exitnode file configs
cp -r $SRC_DIR/src/etc/* /etc/
cp -r $SRC_DIR/src/var/* /var/

# Check if bat0 already has configs
if grep -q "bat0" /etc/network/interfaces
then
  echo "bat0 already configured in /etc/network/interfaces"
else
  cat >>/etc/network/interfaces <<EOF

# Batman interface
# (1) Ugly hack to keep bat0 up: add a dummy tap device
# (2) Add iptables rule to masquerade traffic from the mesh
auto bat0
iface bat0 inet static
        pre-up ip tuntap add dev bat-tap mode tap
        pre-up ip link set bat-tap up
        post-up iptables -t nat -A POSTROUTING -s 10.0.0.0/8 ! -d 10.0.0.0/8 -j MASQUERADE
        pre-down iptables -t nat -D POSTROUTING -s 10.0.0.0/8 ! -d 10.0.0.0/8 -j MASQUERADE
        post-down ip link set bat-tap down
        post-down ip tuntap del dev bat-tap mode tap
        address $MESH_IP
        netmask 255.0.0.0
        mtu $MESH_MTU

# Logical interface to manage adding tunnels to bat0
iface mesh-tunnel inet manual
        up ip link set $IFACE up
        post-up batctl if add $IFACE
        pre-down batctl if del $IFACE
        down ip link set $IFACE down
EOF
fi


# Setup public ip in tunneldigger.cfg

# Sorry this is so ugly - I'm not a very good bash programmer - maxb
CFG="/opt/tunneldigger/broker/l2tp_broker.cfg"
sed -i "" "s/address=[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/address=$PUBLIC_IP/" $CFG
sed -i "" "s/interface=lo/interface=$ETH_IF/" $CFG 

pip install virtualenv

# rm -rf /opt/tunneldigger # ONLY NECESSARY IF WE WANT TO CLEAN UP LAST TUNNELDIGGER INSTALL
git clone https://github.com/sudomesh/tunneldigger.git /opt/tunneldigger
cd /opt/tunneldigger/broker
virtualenv env_tunneldigger
/opt/tunneldigger/broker/env_tunneldigger/bin/pip install -r requirements.txt

#
# cp /opt/tunneldigger/broker/scripts/tunneldigger-broker.init.d /etc/init.d @@TODO: Understand the difference between the two init scripts!
cp /opt/tunneldigger/broker/scripts/tunneldigger-broker.init.d /etc/init.d/tunneldigger

echo "host captive captive 127.0.0.1/32 md5" >> /etc/postgresql/9.1/main/pg_hba.conf 

cp $SRC_DIR/setupcaptive.sql /home/
cd /home
/etc/init.d/postgresql restart; su postgres -c "ls -la";su postgres -c "pwd"; su postgres -c "psql -f setupcaptive.sql -d postgres"

# Squid + redirect stuff for captive portal
# /etc/init.d/squid restart
# /etc/init.d/captive_portal_redirect start

# node stuffs
#cp $SRC_DIR/.profile ~/.profile
# mkdir ~/nvm
# cd ~/nvm
# curl https://raw.githubusercontent.com/creationix/nvm/v0.10.0/install.sh | bash
# source ~/.profile; 
# nvm install 0.10; 
# nvm use 0.10;


# ssh stuffs
# @@TODO: BETTER PASSWORD/Public Key
# echo 'root:sudoer' | chpasswd

# nginx stuffs
cp $SRC_DIR/nginx.conf /etc/nginx/nginx.conf

# IP Forwarding
sed -i.backup 's/\(.*net.ipv4.ip_forward.*\)/# Enable forwarding for mesh (altered by provisioning script)\nnet.ipv4.ip_forward=1/'
