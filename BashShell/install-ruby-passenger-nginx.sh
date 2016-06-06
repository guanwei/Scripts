#!/usr/bin/env bash
# install RVM,ruby,passenger

set -e
[ -n "$DEBUG" ] && set -x

# define functions
echo_title()
{
    echo -e "\e[0;34m$1\e[0m"
}

echo_success()
{
    echo -e "\e[0;32m[✔]\e[0m $1"
}

echo_error()
{
    echo -e "\e[0;31m[✘]\e[0m $1"
}

# check if user is root
if [ $(id -u) != "0" ] ; then
    echo_error "Error: You must run this script as root."
    exit 1
fi

# install RVM
echo_title "Installing RVM..."
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
echo_success "RVM has been installed"

# install ruby
echo_title "Installing ruby..."
yum install -y libyaml-devel libcurl-devel --enablerepo rhui-REGION-rhel-server-optional
rvm install 2.3
rvm use 2.3 --default
echo_success "ruby has been installed"

# install bundler & passenger
echo_title "Installing bundler & passenger..."
gem install bundler passenger --no-ri --no-rdoc
echo_success "bundler & passenger have been installed"

# install passenger-nginx-module
echo_title "Installing passenger-nginx-module..."
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 0644 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab
passenger-install-nginx-module
echo_success "passenger-nginx-module has been installed"

# set up nginx
echo_title "Setting up nginx..."
sed -i -e 's|[ #]*user .*|user   www;|g' -e 's|[ #]*pid .*|pid   /var/run/nginx.pid;|g' /opt/nginx/conf/nginx.conf
curl -sSL https://raw.githubusercontent.com/guanwei/Scripts/master/BashShell/init.d.nginx -o /etc/init.d/nginx
chkconfig nginx on
service nginx start
echo_success "nginx has been set up"
