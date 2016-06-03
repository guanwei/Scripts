#!/usr/bin/env bash

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

# install epel repo
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

# install sslh
if [ -z "$(rpm -qa | grep sslh)" ]; then
    echo_title "Installing sslh..."
    yum -y install sslh
    echo_success "sslh has been installed"
fi
# set up sslh
echo_title "Setting up sslh..."
sed -i 's/{ host: "[^"]*";/{ host: "0.0.0.0";/' /etc/sslh.cfg
chkconfig sslh on   # enable sslh service
service sslh start  # start sslh service
echo_success "sslh has been set up"
