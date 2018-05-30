#!/bin/sh

set -x
set -e

MESH_IP=$1
EXITNODE_IP=$2

MESH_PREFIX=32
MESHNET=100.64.0.0/10
ETH_IF=eth0
L2TP_IF=l2tp0

EXITNODE_REPO=sudomesh/exitnode
TUNNELDIGGER_REPO=wlanslovenija/tunneldigger
TUNNELDIGGER_COMMIT=210037aabf8538a0a272661e08ea142784b42b2c
BABELD_REPO=jech/babeld


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
  software-properties-common \
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

cat >/etc/babeld.conf <<EOF
export-table 20
interface $L2TP_IF wired true
redistribute local ip $MESH_IP/$MESH_PREFIX allow
redistribute local ip 0.0.0.0/0 proto 3 metric 128 allow
redistribute if $ETH_IF metric 128
redistribute local deny
EOF

git clone https://github.com/${EXITNODE_REPO} -b anynode /opt/exitnode
cp -r /opt/exitnode/src_client/etc/* /etc/
cp /opt/exitnode/tunnel_hook $TUNNELDIGGER_HOME
mkdir -p /var/lib/babeld

sed -i.bak "s/<mesh_ip>/$MESH_IP/g" $TUNNELDIGGER_HOME/tunnel_hook

UUID=$(uuidgen)

TUNNEL_START="\/opt\/tunneldigger\/client\/tunneldigger -f -b $EXITNODE_IP:8942 -u $UUID -i $L2TP_IF -s \/opt\/tunneldigger\/tunnel_hook"

sed -i.bak "s/<tunnel_start>/$TUNNEL_START/g" /etc/systemd/system/tunneldigger.service

# for Digital Ocean only
sed -i 's/dns-nameservers.*/dns-nameservers 8.8.8.8/g' /etc/network/interfaces.d/50-cloud-init.cfg
sed -i '/address/a \   \ dns-nameservers 8.8.8.8' /etc/network/interfaces.d/50-cloud-init.cfg 

# start babeld and tunnel digger on reboot
# TODO just start meshrouting, once ported from OpenWrt
systemctl enable tunneldigger
#systemctl enable babeld

service tunneldigger start
#service babeld start

reboot now
