#!/usr/bin/env bash
# install shadowsocks

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

if [ -z "$(rpm -qa | grep epel-release)" ]; then
    echo_title "Installing EPEL repo..."
    SYSTEM=$(uname -r)
    case "$SYSTEM" in
        *el6*)
            rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
        *el7*)
            rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
        *)
            echo "Unknown system: $SYSTEM"; exit 1;;
    esac
    echo_success "EPEL repo has been installed"
fi

echo_title "Installing pip..."
yum -y install python-pip >/dev/null
echo_success "pip has been installed"

echo_title "Upgrading pip..."
pip install --upgrade pip
echo_success "pip has been upgraded"

echo_title "Installing shadowsocks..."
pip install shadowsocks
echo_success "shadowsocks has been installed"

cat > /etc/shadowsocks.json <<EOF
{
  "server": "0.0.0.0",
  "server_port": ${PORT},
  "local_address": "127.0.0.1",
  "local_port": 1080,
  "password": "${PASSWORD}",
  "timeout": 300,
  "method": "aes-256-cfb",
  "fast_open": false
}
EOF

# enable and start service
wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks -O /etc/init.d/shadowsocks
chkconfig shadowsocks on
service shadowsocks start
