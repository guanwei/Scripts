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

SYSTEM=$(uname -r)

if [ -z "$(rpm -qa | grep epel-release)" ]; then
    echo_title "Installing EPEL repo..."
    case "$SYSTEM" in
        *el6*|*amzn1*)
            rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
        *el7*)
            rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
        *)
            echo "Unknown system: $SYSTEM"; exit 1;;
    esac
    echo_success "EPEL repo has been installed"
fi

if [ -z "$(rpm -qa | grep pptpd)" ]; then
    echo_title "Installing pptpd..."
    yum install -y pptpd >/dev/null
    echo_success "pptpd has been installed"
fi

# read vpn user
_VPN_USER="edward"
read -p "Please select vpn user [$_VPN_USER] " VPN_USER
if [ -z "$VPN_USER" ]; then
    VPN_USER=$_VPN_USER
    echo "Selected default - $VPN_USER"
fi

# read vpn password
_VPN_PASS="edward"
read -p "Please select vpn password [$_VPN_PASS] " VPN_PASS
if [ -z "$VPN_PASS" ]; then
    VPN_PASS=$_VPN_PASS
    echo "Selected default - $VPN_PASS"
fi

echo_title "Setting up pptpd vpn..."
if grep -q '^net.ipv4.ip_forward =' /etc/sysctl.conf ; then
    sed -i 's/net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
else
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi

sysctl -q -p

if [ -z "$(grep '^ms-dns' /etc/ppp/options.pptpd)" ]; then
cat >> /etc/ppp/options.pptpd <<EOF
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF
fi

if [ -z "$(grep "^$VPN_USER pptpd" /etc/ppp/chap-secrets)" ]; then
    echo "$VPN_USER pptpd $VPN_PASS *" >> /etc/ppp/chap-secrets
else
    sed -i "s/$VPN_USER pptpd [^ ]*/$VPN_USER pptpd $VPN_PASS/g" /etc/ppp/chap-secrets
fi

chkconfig pptpd on
service pptpd restart

# enable ip masquerade
ETH=$(route | grep default | awk '{print $NF}')

iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE
if [ -z "$(grep '^iptables -t nat -A POSTROUTING' /etc/rc.local)" ]; then
    echo "iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE" >> /etc/rc.local
fi
echo_success "pptpd vpn has been set up"

# output info
VPN_IP=$(curl -s ipv4.icanhazip.com)

echo -e "\nYou can now connect to your VPN via your external IP \033[32m${VPN_IP}\033[0m"
echo -e "Username: \033[32m${VPN_USER}\033[0m"
echo -e "Password: \033[32m${VPN_PASS}\033[0m"
