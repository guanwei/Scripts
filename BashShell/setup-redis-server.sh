#!/usr/bin/env bash

set -e
[ -n "$DEBUG" ] && set -x

# check if user is root
if [ $(id -u) != "0" ] ; then
    echo -e "\033[31mError: You must run this script as root.\033[0m"
    exit 1
fi

PATH=/usr/local/bin:$PATH

SRC_PATH="/usr/local/src"
cd "$SRC_PATH"

# install gcc
yum -y install gcc

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
