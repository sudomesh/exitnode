FROM debian:wheezy

# For nginx
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list
RUN echo "deb-src http://nginx.org/packages/debian/ wheezy nginx" >> /etc/apt/sources.list

# All our build dependencies
RUN apt-get update && apt-get install -y --force-yes \
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
    linux-headers* \
    python \
    vim

# All exitnode file configs
ADD src/etc /etc
ADD src/var /var

RUN mkdir /opt

WORKDIR /opt
RUN git clone https://github.com/sudomesh/tunneldigger.git
RUN cp /opt/broker/scripts/tunneldigger-broker.init.d /etc/init.d

RUN echo "host captive captive 127.0.0.1/32 md5" >> /etc/postgresql/9.1/main/pg_hba.conf 

ADD setupcaptive.sql /home/

WORKDIR /home

RUN /etc/init.d/postgresql restart; su postgres -c "ls -la";su postgres -c "pwd"; su postgres -c "psql -f setupcaptive.sql -d postgres"

# Squid + redirect stuff for captive portal
# RUN /etc/init.d/squid restart
# RUN sudo /etc/init.d/captive_portal_redirect start

# node stuffs
ADD .profile /root/.profile
RUN mkdir /root/nvm
WORKDIR /root/nvm
RUN touch /root/.profile
RUN usermod -d /root -m root
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.10.0/install.sh | bash
RUN cat /root/.profile
RUN . /root/.profile; \
    nvm install 0.10; \
    nvm use 0.10;


# ssh stuffs
# @@TODO: BETTER PASSWORD/Public Key
RUN echo 'root:sudoer' | chpasswd

# nginx stuffs
ADD nginx.conf /etc/nginx/nginx.conf
RUN mkdir /data; mkdir /data/www;

EXPOSE 80
EXPOSE 22 

ADD 00_sshd /opt/run/
ADD 01_nginx /opt/run/
ADD run_all /opt/bin/
RUN chmod 744 /opt/run/*
RUN chmod 744 /opt/bin/*

RUN ls -la /opt/run; ls -la /opt/bin;

RUN modprobe batman-adv

ENTRYPOINT ["/opt/bin/run_all"]
