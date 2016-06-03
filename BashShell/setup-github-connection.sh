#!/usr/bin/env bash

set -e
[ -n "$DEBUG" ] && set -x

# define functions
echo_title()
{
    echo -e " \e[0;34m$1\e[0m"
}

# install git
if [ -z "$(rpm -qa | grep git)" ]; then
    echo_title "Installing git..."
    sudo yum -y install git
fi

# read user name
_USER_NAME="Edward Guan"
read -p "Please select user name [$_USER_NAME] " USER_NAME
if [ -z "$USER_NAME" ] ; then
    USER_NAME=$_USER_NAME
    echo "Selected default - $USER_NAME"
fi

# read user email
_USER_EMAIL="285006386@qq.com"
read -p "Please select user email [$_USER_EMAIL] " USER_EMAIL
if [ -z "$USER_EMAIL" ] ; then
    USER_EMAIL=$_USER_EMAIL
    echo "Selected default - $USER_EMAIL"
fi

# config git configuration
git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

# read ssh key name
_SSH_KEY_NAME="id_rsa"
read -p "Please select ssh key name [$_SSH_KEY_NAME] " SSH_KEY_NAME
if [ -z "$SSH_KEY_NAME" ] ; then
    SSH_KEY_NAME=$_SSH_KEY_NAME
    echo "Selected default - $SSH_KEY_NAME"
fi

SSH_KEY="$HOME/.ssh/$SSH_KEY_NAME"
SSH_CONFIG="$HOME/.ssh/config"

# create ssh key
if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t rsa -f "$SSH_KEY" -C "$USER_EMAIL"
fi

if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

if [ -z "$(grep 'Host github.com' "$SSH_CONFIG")" ]; then
cat >> "$SSH_CONFIG" << EOF
##############
# For Github #
##############
Host github.com
  Hostname ssh.github.com
  Port 443
  PreferredAuthentications publickey
  IdentityFile "$SSH_KEY"
EOF
fi

echo ""
echo_title "===== SSH public key ====="
cat "$SSH_KEY.pub"

echo ""
echo "Add below ssh pubic key to your github, then run 'ssh -T git@github.com' to test."

cat << EOF

===== create a new repository on the command line =====
echo "# readme" >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin git@github.com:<account>/<repository>.git
git push -u origin master

==== push an existing repository from the command line ====
git remote add origin git@github.com:<account>/<repository>.git
git push -u origin master

EOF
