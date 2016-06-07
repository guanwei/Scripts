#!/usr/bin/env bash

set -e
[ -n "$DEBUG" ] && set -x

# define functions
echo_title()
{
    echo -e "\e[34m$1\e[0m"
}

echo_success()
{
    echo -e "\e[32m[✔]\e[0m $1"
}

echo_error()
{
    echo -e "\e[31m[✘]\e[0m $1"
}

# check if user is root
if [ $(id -u) != "0" ] ; then
    echo_error "Error: You must run this script as root."
    exit 1
fi

SYSTEM=$(uname -r)

# install epel repo
if [ -z "$(rpm -qa | grep epel-release)" ]; then
    echo_title "Installing EPEL repo..."
            rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
        *el7*)
            rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
        *)
            echo "Unknown system: $SYSTEM"; exit 1;;
    esac
    echo_success "EPEL repo has been installed"
fi

# install sslh
if [ -z "$(rpm -qa | grep sslh)" ]; then
    echo_title "Installing sslh..."
    yum install -y sslh --enablerepo=epel >/dev/null
    echo_success "sslh has been installed"
fi
# set up sslh
echo_title "Setting up sslh..."
case "$SYSTEM" in
    *el6*|*amzn1*)
        sed -i 's|[ #]*SSLH_USER=.*|SSLH_USER=sslh|g' /etc/sysconfig/sslh
        sed -i 's|[ #]*DAEMON_OPTS=.*|DAEMON_OPTS="-p 0.0.0.0:443 --ssh 127.0.0.1:22 --openvpn 127.0.0.1:1194 --ssl 127.0.0.1:443 --anyprot 127.0.0.1:443"|g' /etc/sysconfig/sslh
        curl -sSL https://raw.githubusercontent.com/guanwei/Scripts/master/BashShell/init.d.sslh -o /etc/init.d/sslh
        ;;
    *el7*)
        sed -i 's/{ host: "[^"]*";/{ host: "0.0.0.0";/' /etc/sslh.cfg
        ;;
esac
echo_success "sslh has been set up"

# enable & start sslh service
chkconfig sslh on
service sslh start
