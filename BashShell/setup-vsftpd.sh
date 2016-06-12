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

# read ftp user name
_USER_NAME="edward"
read -p "Please select ftp user name [$_USER_NAME] " USER_NAME
if [ -z "$USER_NAME" ] ; then
  USER_NAME=$_USER_NAME
  echo "Selected default - $USER_NAME"
fi

# read ftp user password
_USER_PASSWD="edward"
read -p "Please select ftp user password [$_USER_PASSWD] " USER_PASSWD
if [ -z "$USER_PASSWD" ] ; then
  USER_PASSWD=$_USER_PASSWD
  echo "Selected default - $USER_PASSWD"
fi

# install vsftpd
echo_title "Installing vsftpd..."
yum install -y vsftpd db4 db4-utils >/dev/null
echo_success "vsftpd has been created"

# set up vsftpd
echo_title "Setting up vsftpd..."

# create virtual user db file
touch /etc/vsftpd/vuser_passwd.txt
if [ -z "$(grep "$USER_NAME" /etc/vsftpd/vuser_passwd.txt)" ]; then
cat >> /etc/vsftpd/vuser_passwd.txt << EOF
$USER_NAME
$USER_PASSWD
EOF
db_load -T -t hash -f /etc/vsftpd/vuser_passwd.txt /etc/vsftpd/vuser_passwd.db
fi

# update vsftpd pam file
cat > /etc/pam.d/vsftpd << EOF
#%PAM-1.0
auth       required     pam_userdb.so     db=/etc/vsftpd/vuser_passwd
account    required     pam_userdb.so     db=/etc/vsftpd/vuser_passwd
EOF

# mkdir ftp user root
USER_ROOT="/var/ftp/$USER_NAME"
mkdir -p $USER_ROOT
chown -R ftp:ftp $USER_ROOT

sed -i 's/[ #]*anonymous_enable=.*/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
sed -i 's/[ #]*chroot_local_user=.*/chroot_local_user=YES/g' /etc/vsftpd/vsftpd.conf
if [ -z "$(grep 'Virtual User configuration' /etc/vsftpd/vsftpd.conf)" ]; then
cat >> /etc/vsftpd/vsftpd.conf << EOF

# Virtual User configuration
guest_enable=YES
local_root=/var/ftp/\$USER
user_sub_token=\$USER
virtual_use_local_privs=YES
allow_writeable_chroot=YES
hide_ids=YES
EOF
fi

if [ -z "$(grep 'Passive Mode configuration' /etc/vsftpd/vsftpd.conf)" ]; then
cat >> /etc/vsftpd/vsftpd.conf << EOF

# Passive Mode configuration
pasv_enable=YES
pasv_min_port=1024
pasv_max_port=1048
pasv_address=$PUBLIC_IP
EOF
fi

echo_success "vsftpd has been set up"

# enable & start vsftpd service
chkconfig vsftpd on
service vsftpd start

cat << EOF

===== create user for vsftpd =====
sudo echo <username> >> /etc/vsftpd/vuser_passwd.txt
sudo echo <password> >> /etc/vsftpd/vuser_passwd.txt
sudo db_load -T -t hash -f /etc/vsftpd/vuser_passwd.txt /etc/vsftpd/vuser_passwd.db

==== open firewall port for vsftpd ====
<Protocol>  <PortRange>  <Source>
TCP	           20-21	   0.0.0.0/0
TCP	         1024-1048	 0.0.0.0/0

EOF
