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

TIME_ZONE="Asia/Shanghai"

# set timezone
echo_title "Setting timezone [$TIME_ZONE]..."
rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
echo_success "Timezone has been set to [$TIME_ZONE]"

# disabe selinux
echo_title "Disabling selinux..."
if [ -e /etc/selinux/config ]; then
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi
echo_success "selinux has been disabled"

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

# update system
yum update -y
