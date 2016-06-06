#!/usr/bin/env bash

set -e
[ -n "$DEBUG" ] && set -x

# install pyenv
curl -sL https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

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
sudo yum -y install zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel
pyenv install -v 3.5.1
pyenv rehash
pyenv global 3.5.1
pip install --upgrade pip
pyenv version
