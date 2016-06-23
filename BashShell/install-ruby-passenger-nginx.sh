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
SYSTEM=$(uname -r)
case "$SYSTEM" in
    *el6*|*amzn1*)
        yum install -y libyaml-devel libcurl-devel >/dev/null;;
    *el7*)
        yum install -y libyaml-devel libcurl-devel --enablerepo rhui-REGION-rhel-server-optional >/dev/null;;
    *)
        echo "Unknown system: $SYSTEM"; exit 1;;
esac
rvm install 2.3
rvm use 2.3 --default
echo_success "ruby has been installed"

# install bundler & passenger
echo_title "Installing bundler & passenger..."
gem install bundler passenger --no-ri --no-rdoc
echo_success "bundler & passenger have been installed"

# create swap file
echo_title "Creating swap file..."
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 0644 /swapfile
mkswap /swapfile
swapon /swapfile
if [ -z "$(grep '/swapfile' /etc/fstab)" ]; then
    echo '/swapfile none swap defaults 0 0' >> /etc/fstab
fi
echo_success "swap file has been created"

NGINX_PATH="/opt/nginx"
DOMAIN=$(hostname -s)

# install passenger-nginx-module
echo_title "Installing passenger-nginx-module..."
yum install -y gcc pcre-devel openssl-devel zlib-devel
passenger-install-nginx-module --auto --auto-download --prefix="$NGINX_PATH"
echo_success "passenger-nginx-module has been installed"

# create ssl cert
echo_title "Create ssl cert..."
mkdir "$NGINX_PATH/conf/ssl" && cd "$NGINX_PATH/conf/ssl"
openssl genrsa -des3 -out $DOMAIN.key 1024
SUBJECT="/C=CN/ST=Shanghai/L=Shanghai/O=IT/OU=IT/CN=$DOMAIN"
openssl req -new -subj $SUBJECT -key $DOMAIN.key -out $DOMAIN.csr
mv $DOMAIN.key $DOMAIN.origin.key
openssl rsa -in $DOMAIN.origin.key -out $DOMAIN.key
openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
echo_success "ssl cert has been created"

# set up nginx
echo_title "Setting up nginx..."
if [ -z "$(grep 'www' /etc/passwd)" ]; then
    useradd -M -s /bin/nologin www
fi
sed -i -e 's|[ #]*user .*|user   www;|g' -e 's|[ #]*pid .*|pid   /var/run/nginx.pid;|g' /opt/nginx/conf/nginx.conf
curl -sSL https://raw.githubusercontent.com/guanwei/Scripts/master/BashShell/init.d.nginx -o /etc/init.d/nginx
chmod +x /etc/init.d/nginx
chkconfig nginx on
service nginx start
echo_success "nginx has been set up"
