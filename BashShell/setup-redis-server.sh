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

PATH=/usr/local/bin:$PATH

# change current path
cd /usr/local/src

# install gcc
yum install -y gcc >/dev/null

# download redis
if [ ! -f redis-stable.tar.gz ]; then
    wget http://download.redis.io/releases/redis-stable.tar.gz
fi

# unzip redis
tar -zxf redis-stable.tar.gz

# make and install redis
cd redis-stable
make clean && make MALLOC=libc && make install

# run install redis-server shell
sh ./utils/install_server.sh
