# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  #
  # @@TODO: Add libnl-dev in order to compile tunneldigger client

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "chef/debian-7.4"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8081" will access port 8080 on the guest machine.
  config.vm.network "forwarded_port", guest: 8080, host: 8081
  config.vm.network "forwarded_port", guest: 2020, host: 2020

  $script = <<SCRIPT
  echo "provisioning"
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
    vim \
    tmux

# Totally uneccessary fancy vim config
  git clone git://github.com/maxb/vimrc.git /root/.vim_runtime
  sh /root/.vim_runtime/install_awesome_vimrc.sh

# All exitnode file configs
  cp -r /vagrant/src/etc/* /etc/
  cp -r /vagrant/src/var/* /var/

  rm -rf /opt/tunneldigger # ONLY NECESSARY IF WE WANT TO CLEAN UP LAST TUNNELDIGGER INSTALL
  git clone https://github.com/sudomesh/tunneldigger.git /opt/tunneldigger
  cd /opt/tunneldigger/broker
  virtualenv env_tunneldigger
  source env_tunneldigger/bin/activate
  pip install -r requirements.txt
  deactivate
  # virtualenv venv
  # source /opt/tunneldigger/broker/venv/bin/activate
  # pip install -r requirements.txt
  #
  # cp /opt/tunneldigger/broker/scripts/tunneldigger-broker.init.d /etc/init.d @@TODO: Understand the difference between the two init scripts!
  cp /opt/tunneldigger/broker/scripts/tunneldigger-broker.init.d /etc/init.d/tunneldigger

  echo "host captive captive 127.0.0.1/32 md5" >> /etc/postgresql/9.1/main/pg_hba.conf 


  # git clone http://git.open-mesh.org/batman-adv.git /home/batman-adv
  # cd /home/batman-adv
  # make && make install
  #
  modprobe batman-adv

  cp /vagrant/setupcaptive.sql /home/
  cd /home
  /etc/init.d/postgresql restart; su postgres -c "ls -la";su postgres -c "pwd"; su postgres -c "psql -f setupcaptive.sql -d postgres"

# Squid + redirect stuff for captive portal
# /etc/init.d/squid restart
# /etc/init.d/captive_portal_redirect start

# node stuffs
  cp /vagrant/.profile /root/.profile
  mkdir /root/nvm
  cd /root/nvm
  touch /root/.profile
  usermod -d /root -m root
  curl https://raw.githubusercontent.com/creationix/nvm/v0.10.0/install.sh | bash
  cat /root/.profile
  . /root/.profile; \
      nvm install 0.10; \
      nvm use 0.10;


# ssh stuffs
# @@TODO: BETTER PASSWORD/Public Key
  echo 'root:sudoer' | chpasswd

  alias ls="ls -la"

# nginx stuffs
  cp /vagrant/nginx.conf /etc/nginx/nginx.conf

SCRIPT

  config.vm.provision "shell", inline: $script
    

  # config.vm.provision "docker" do |d|
  # end

#   config.vm.provision "docker" do |d|
#     d.build_image "/vagrant/docker", args:"-t maxb/exit1"
#     d.run "maxb/exit1", args:"-p 8080:80 -p 2020:22 -d"
#   end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with CFEngine. CFEngine Community packages are
  # automatically installed. For example, configure the host as a
  # policy server and optionally a policy file to run:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.am_policy_hub = true
  #   # cf.run_file = "motd.cf"
  # end
  #
  # You can also configure and bootstrap a client to an existing
  # policy server:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.policy_server_address = "10.0.2.15"
  # end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file default.pp in the manifests_path directory.
  #
  # config.vm.provision "puppet" do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "site.pp"
  # end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # config.vm.provision "chef_solo" do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { mysql_password: "foo" }
  # end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision "chef_client" do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"
end
