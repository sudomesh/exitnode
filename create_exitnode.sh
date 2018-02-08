#!/bin/sh

IP=$1

MESH_IP=100.64.0.42
MESH_PREFIX=32
MESHNET=100.64.0.0/10
ETH_IF=eth0
PUBLIC_IP=$IP
PUBLIC_SUBNET="$IP/29"

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

KERNEL_VERSION=$(uname -r)
echo kernel version [$KERNEL_VERSION]

apt-get install -y --force-yes \
  cmake \
  libnl-3-dev \
  libnl-genl-3-dev \
  build-essential \
  pkg-config \
  linux-image-extra-$(uname -r)

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

pip install --upgrade pip

pip install netfilter
pip install virtualenv

git clone https://github.com/sudomesh/tunneldigger.git /opt/tunneldigger
cd /opt/tunneldigger/broker
virtualenv env_tunneldigger
/opt/tunneldigger/broker/env_tunneldigger/bin/pip install -r requirements.txt


cat >/opt/tunneldigger/broker/scripts/up_hook.sh <<EOF
#!/bin/sh
ip link set \$3 up
ip addr add $MESH_IP/$MESH_PREFIX dev \$3
ip link set dev \$3 mtu \$4
babeld -a \$3
EOF

chmod 755 /opt/tunneldigger/broker/scripts/up_hook.sh

cat >/etc/babeld.conf <<EOF
redistribute local ip $MESH_IP/$MESH_PREFIX allow
redistribute local ip 0.0.0.0/0 proto 3 metric 128 allow
redistribute local ip $PUBLIC_SUBNET proto 0 deny
redistribute local deny
EOF

cp /opt/tunneldigger/broker/l2tp_broker.cfg.example /opt/tunneldigger/broker/l2tp_broker.cfg

# Setup public ip in tunneldigger.cfg
CFG="/opt/tunneldigger/broker/l2tp_broker.cfg"
# This following like doesn't seem to be working!
sed -i.bak "s#address=[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+#address=$PUBLIC_IP#" $CFG
sed -i.bak "s#interface=lo#interface=$ETH_IF#" $CFG 

# adding init.d scripts to startup
#update-rc.d tunneldigger defaults
#update-rc.d babeld defaults

#service tunneldigger start
#service babeld start

# IP Forwarding
sed -i.backup 's/\(.*net.ipv4.ip_forward.*\)/# Enable forwarding for mesh (altered by provisioning script)\nnet.ipv4.ip_forward=1/' /etc/sysctl.conf
echo "1" > /proc/sys/net/ipv4/ip_forward

#reboot now
