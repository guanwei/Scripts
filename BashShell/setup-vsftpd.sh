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

PUBLIC_IP=$(curl -s ipv4.icanhazip.com)

# read ftp root
_FTP_ROOT=/var/www/html
read -p "Please select ftp root [$_FTP_ROOT] " FTP_ROOT
if [ -z "$FTP_ROOT" ] ; then
    FTP_ROOT=$_FTP_ROOT
    echo "Selected default - $FTP_ROOT"
fi

# mkdir ftp root
if [ ! -f "$FTP_ROOT" ]; then
  echo_title "Creating FTP root ${FTP_ROOT}..."
  mkdir -p $FTP_ROOT
  chmod 755 $FTP_ROOT
  echo_success "FTP root has been created"
fi

# install vsftpd
echo_title "Installing vsftpd..."
yum install -y vsftpd >/dev/null
echo_success "vsftpd has been created"

# set up vsftpd
echo_title "Setting up vsftpd..."
sed -i 's/[ #]*anonymous_enable=.*/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
sed -i 's/[ #]*chroot_local_user=.*/chroot_local_user=YES/g' /etc/vsftpd/vsftpd.conf
if [ -z "$(grep 'Additional configuration' /etc/vsftpd/vsftpd.conf)" ]; then
cat >> /etc/vsftpd/vsftpd.conf << EOF
# Additional configuration
pasv_enable=YES
pasv_min_port=1024
pasv_max_port=1048
pasv_address=$PUBLIC_IP
local_root=$FTP_ROOT
EOF
fi
echo_success "vsftpd has been set up"

# enable & start vsftpd service
chkconfig vsftpd on
service vsftpd start

cat << EOF

===== create user for vsftpd =====
sudo adduser <username>
sudo passwd <username>

==== open firewall port for vsftpd ====
<Protocol>  <PortRange>  <Source>
TCP	           20-21	   0.0.0.0/0
TCP	         1024-1048	 0.0.0.0/0

EOF
