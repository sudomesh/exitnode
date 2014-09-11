#!/bin/sh

cd ~/

# install git
apt-get update && apt-get install git -y --force-yes

# grab script
git clone https://github.com/sudomesh/exitnode.git
cd exitnode/

# run script
current_dir="$PWD"
./provision.sh $current_dir
