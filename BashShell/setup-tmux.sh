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

# install tmux
echo_title "Installing tmux..."
yum install -y tmux >/dev/null
echo_success "tmux has been installed"

# enable 256 colors
echo_title "Setting up tmux..."
cat >> ~/.tmux.conf <<EOF
set -g default-terminal "screen-256color"
EOF
cat >> ~/.bashrc <<EOF
alias tmux="tmux -2"
EOF
echo_success "tmux has been set up"
