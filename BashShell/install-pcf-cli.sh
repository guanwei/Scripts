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

PCF_CLI_URL="https://s3.amazonaws.com/go-cli/releases/v6.19.0/cf-cli-installer_6.19.0_x86-64.rpm"
PCF_CLI_RPM=${PCF_CLI_URL##*/}

echo_title "Downloading PCF CLI..."
if [ ! -f "$PCF_CLI_RPM" ]; then
  wget -O "$PCF_CLI_RPM" "$PCF_CLI_URL"
  echo_success "PCF CLI has been downloaded"
else
  echo_success "PCF CLI is already downloaded"
fi

echo_title "Installing PCF CLI..."
if [ -z "$(rpm -qa | grep cf-cli)" ]; then
  rpm -ivh "$PCF_CLI_RPM"
  echo_success "PCF CLI has been installed"
else
  echo_success "PCF CLI is already installed"
fi

#YOUR_LANGUAGE="zh_Hans"
#cf config --locale $YOUR_LANGUAGE
