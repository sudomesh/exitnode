#!/bin/sh

set -x
set -e

#IP=$1
#GATEWAY_IP=$2

MESH_IP=100.65.120.129
MESH_PREFIX=32
MESHNET=100.64.0.0/10
ETH_IF=eth0
#PUBLIC_IP=$IP
#PUBLIC_SUBNET="$IP/29"

EXITNODE_REPO=sudomesh/exitnode
TUNNELDIGGER_REPO=wlanslovenija/tunneldigger
TUNNELDIGGER_COMMIT=210037aabf8538a0a272661e08ea142784b42b2c
BABELD_REPO=sudomesh/babeld


KERNEL_VERSION=$(uname -r)
echo kernel version [$KERNEL_VERSION]

release_info="$(cat /etc/*-release)"
echo "release_info=$release_info"
release_name="$(echo "$release_info" | grep ^NAME= | cut -d'=' -f2)"
echo "release_name=[$release_name]"
DEBIAN_FRONTEND=noninteractive apt-get update

if [ "$release_name" == '"Ubuntu"' ]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --force-yes \
    linux-image-extra-$(uname -r)
fi 

DEBIAN_FRONTEND=noninteractive apt-get install -yq --force-yes \
  build-essential \
  ca-certificates \
  curl \
  git \
  zlib1g \
  zlib1g-dev \
  libssl-dev \
  libxslt1-dev \
  kmod \
  bridge-utils \
  openssh-server \
  openssl \
  perl \
  dnsmasq \
  procps \
  python-psycopg2 \
  software-properties-common \
  python \
  python-dev \
  python-pip \
  iproute \
  libnetfilter-conntrack3 \
  libevent-dev \
  ebtables \
  vim \
  iproute \
  bridge-utils \
  libnetfilter-conntrack-dev \
  libnfnetlink-dev \
  libffi-dev \
  libevent-dev \
  tmux

DEBIAN_FRONTEND=noninteractive apt-get install -yq --force-yes \
  cmake \
  libnl-3-dev \
  libnl-genl-3-dev \
  build-essential \
  pkg-config

mkdir ~/babel_build
git clone https://github.com/${BABELD_REPO} ~/babel_build/
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

TUNNELDIGGER_HOME=/opt/tunneldigger
git clone https://github.com/${TUNNELDIGGER_REPO} $TUNNELDIGGER_HOME
cd $TUNNELDIGGER_HOME
git checkout $TUNNELDIGGER_COMMIT
cd client
cmake .
make

mkdir scripts

TUNNELDIGGER_UPHOOK_SCRIPT=$TUNNELDIGGER_HOME/client/scripts/up_hook.sh
TUNNELDIGGER_DOWNHOOK_SCRIPT=$TUNNELDIGGER_HOME/client/scripts/down_hook.sh

cat >$TUNNELDIGGER_UPHOOK_SCRIPT <<EOF
#!/bin/sh
ip link set \$3 up
ip addr add $MESH_IP/$MESH_PREFIX dev \$3
ip link set dev \$3 mtu 1446
babeld -a \$3
EOF

chmod 755 $TUNNELDIGGER_UPHOOK_SCRIPT 

cat >$TUNNELDIGGER_DOWNHOOK_SCRIPT <<EOF
#!/bin/sh
babeld -x \$3
EOF

chmod 755 $TUNNELDIGGER_DOWNHOOK_SCRIPT 

cat >/etc/babeld.conf <<EOF
redistribute local ip $MESH_IP/$MESH_PREFIX allow
redistribute local ip 0.0.0.0/0 proto 3 metric 128 allow
redistribute if $ETH_IF metric 128
redistribute local deny
EOF

git clone https://github.com/${EXITNODE_REPO} /opt/exitnode
cp -r /opt/exitnode/src_client/etc/* /etc/
#cp -r /opt/exitnode/src_client/opt/* /opt/
mkdir -p /var/lib/babeld

# Setup public ip in tunneldigger.cfg
#CFG="$TUNNELDIGGER_HOME/broker/l2tp_broker.cfg"

#sed -i.bak "s#address=[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+#address=$PUBLIC_IP#" $CFG
#sed -i.bak "s#interface=lo#interface=$ETH_IF#" $CFG 

# for Digital Ocean only
sed -i 's/dns-nameservers.*/dns-nameservers 8.8.8.8/g' /etc/network/interfaces.d/50-cloud-init.cfg
sed -i '/address/a \   \ dns-nameservers 8.8.8.8' /etc/network/interfaces.d/50-cloud-init.cfg 

# start babeld and tunnel digger on reboot
systemctl enable tunneldigger
systemctl enable babeld

service tunneldigger start
service babeld start

reboot now
