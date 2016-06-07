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

VUNDLE_PATH="$HOME/.vim/bundle/vundle"
TODAY=$(date +%Y%m%d_%s)

if [ -e ~/.vimrc ] || [ -e ~/.vim ]; then
    echo_title "Backing up vim configuration..."
    for i in ~/.vimrc ~/.vim; do
        [ -e "$i" ] && [ ! -L "$i" ] && mv -v "$i" "$i.$TODAY";
    done
    echo_success "Vim configuration have been backed up"
fi

echo_title "Installing vundle..."
if [ -e "$VUNDLE_PATH" ]; then
    cd "$VUNDLE_PATH" && git pull origin master
else
    mkdir -p "$VUNDLE_PATH"
    git clone https://github.com/gmarik/vundle.git "$VUNDLE_PATH"
fi
echo_success "Vundle has been installed"

echo_title "Installing vim..."
yum -y install vim ctags the_silver_searcher

echo_title "Configuring vim..."
curl -ssL https://raw.githubusercontent.com/guanwei/scripts/master/vimrc.basic -o ~/.vimrc
vim -u ~/.vimrc "+set nomore" "+BundleInstall!" "+qall"
echo_success "Vim has been configured"
