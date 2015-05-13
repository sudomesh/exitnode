#!/bin/sh

MESH_IP=100.64.0.1
MESH_PREFIX=32
MESHNET=100.64.0.0/10
ETH_IF=eth0
PUBLIC_IP="$(ip addr show $ETH_IF | grep -oh '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')"
PUBLIC_SUBNET="$(ip addr show $ETH_IF | grep -oh '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\/[0-9]*')"

if [ "$#" -le 0 ]
then
  SRC_DIR="/vagrant/"
else
  SRC_DIR="$1"
fi

apt-get update && apt-get install -y --force-yes \
  build-essential \
  ca-certificates \
  curl \
  git \
  libssl-dev \
  libxslt1-dev \
  module-init-tools \
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
  tmux \
  linux-headers-amd64

mkdir ~/babel_build
git clone https://github.com/sudomesh/babeld.git ~/babel_build/
cd ~/babel_build

make && make install

REQUIRED_MODULES="nf_conntrack_netlink nf_conntrack nfnetlink l2tp_netlink l2tp_core l2tp_eth"

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

pip install virtualenv

# rm -rf /opt/tunneldigger # ONLY NECESSARY IF WE WANT TO CLEAN UP LAST TUNNELDIGGER INSTALL
git clone https://github.com/sudomesh/tunneldigger.git /opt/tunneldigger
cd /opt/tunneldigger/broker
virtualenv env_tunneldigger
/opt/tunneldigger/broker/env_tunneldigger/bin/pip install -r requirements.txt

#
# cp /opt/tunneldigger/broker/scripts/tunneldigger-broker.init.d /etc/init.d @@TODO: Understand the difference between the two init scripts!
cp /opt/tunneldigger/broker/scripts/tunneldigger-broker.init.d /etc/init.d/tunneldigger

# Check if babel tunnel is already configured 
if grep -q "babeld" /opt/tunneldigger/broker/scripts/up_hook.sh
then
  echo "babel tunnel already configured in /opt/tunneldigger/broker/scripts/up_hook.sh"
else
  cat >/opt/tunneldigger/broker/scripts/up_hook.sh <<EOF
  #!/bin/sh
  ip link set \$3 up
  ip addr add $MESH_IP/$MESH_PREFIX dev \$3
  ip link set dev \$3 mtu 1438
  babeld -a \$3
EOF
fi

cat >/etc/babeld.conf <<EOF
redistribute local ip $MESH_IP/$MESH_PREFIX allow
redistribute local ip 0.0.0.0/0 proto 3 metric 128 allow
redistribute local ip $PUBLIC_SUBNET proto 0 deny
redistribute local deny
EOF

cp $SRC_DIR/l2tp_broker.cfg /opt/tunneldigger/broker/l2tp_broker.cfg

# Setup public ip in tunneldigger.cfg
# Sorry this is so ugly - I'm not a very good bash programmer - maxb
CFG="/opt/tunneldigger/broker/l2tp_broker.cfg"
# This following like doesn't seem to be working!
sed -i.bak "s#address=[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+#address=$PUBLIC_IP#" $CFG
sed -i.bak "s#interface=lo#interface=$ETH_IF#" $CFG 

# Setup address for gateway script
sed -i.bak "s#MESHNET=[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/[0-9]\+#MESHNET=$MESHNET#" /etc/init.d/gateway


echo "host captive captive 127.0.0.1/32 md5" >> /etc/postgresql/9.1/main/pg_hba.conf 

cp $SRC_DIR/setupcaptive.sql /home/
cd /home
/etc/init.d/postgresql restart; su postgres -c "ls -la";su postgres -c "pwd"; su postgres -c "psql -f setupcaptive.sql -d postgres"

# @@TODO - Do we need to add these to startup?
# adding init.d scripts to startup
update-rc.d tunneldigger defaults
# update-rc.d gateway defaults
update-rc.d babeld defaults

service tunneldigger start
# service gateway start
service babeld start

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

# nginx stuffs
echo "deb http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list
apt-get update
apt-get install -y --force-yes nginx
cp $SRC_DIR/nginx.conf /etc/nginx/nginx.conf
update-rc.d nginx defaults
service nginx start

# IP Forwarding
sed -i.backup 's/\(.*net.ipv4.ip_forward.*\)/# Enable forwarding for mesh (altered by provisioning script)\nnet.ipv4.ip_forward=1/' /etc/sysctl.conf
echo "1" > /proc/sys/net/ipv4/ip_forward

shutdown -r now
