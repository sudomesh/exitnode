#!/bin/sh

PUBLIC_IP=123.1.1.1 
MESH_IP=10.0.33.1
MESH_MTU=1400

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

modprobe nf_conntrack_netlink
modprobe nf_conntrack           
modprobe nfnetlink              
modprobe l2tp_netlink           
modprobe l2tp_core   
modprobe batman-adv

#@@TODO: check if already in /etc/modules and if not echo >> into /etc/modules

# Totally uneccessary fancy vim config
git clone https://github.com/max-b/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh

# All exitnode file configs
cp -r $SRC_DIR/src/etc/* /etc/
cp -r $SRC_DIR/src/var/* /var/

# Check if bat0 already has configs
if grep -Fxq "bat0" /etc/network/interfaces
then
  echo "bat0 already configured in /etc/network/interfaces"
else
  echo $'iface bat0 inet static\n  address $MESH_IP\n  netmask 255.0.0.0\n  mtu $MESH_MTU' >> /etc/network/interfaces
fi

# Setup public ip in tunneldigger.cfg

CFG="/opt/tunneldigger/broker/l2tp_broker.cfg"
CFG_TMP="/tmp/tun_cfg_new"
sed "s/address=[0-9+].[0-9+].[0-9+].[0-9+]/address=$PUBLIC_IP/" $CFG >$CFG_TMP
cp $CFG_TMP $CFG

pip install virtualenv

rm -rf /opt/tunneldigger # ONLY NECESSARY IF WE WANT TO CLEAN UP LAST TUNNELDIGGER INSTALL
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
cp $SRC_DIR/.profile ~/.profile
mkdir ~/nvm
cd ~/nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.10.0/install.sh | bash
source ~/.profile; 
nvm install 0.10; 
nvm use 0.10;


# ssh stuffs
# @@TODO: BETTER PASSWORD/Public Key
# echo 'root:sudoer' | chpasswd

alias ls="ls -la"

# nginx stuffs
cp $SRC_DIR/nginx.conf /etc/nginx/nginx.conf


