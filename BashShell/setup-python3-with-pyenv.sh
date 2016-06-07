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

# install pyenv
curl -sSL https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

if [ -z "$(grep '# pyenv' ~/.bash_profile)" ] ; then
    cat >> ~/.bash_profile << EOF

# pyenv
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF
    source ~/.bash_profile
fi

# update pyenv
pyenv update

# install python3
sudo yum install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel >/dev/null
pyenv install -v 3.5.1
pyenv rehash
pyenv global 3.5.1
pip install --upgrade pip
pyenv version
