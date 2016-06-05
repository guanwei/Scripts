# install RVM,ruby,passenger

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh

# install ruby
yum install -y libyaml-devel libcurl-devel --enablerepo rhui-REGION-rhel-server-optional

rvm install 2.3
rvm use 2.3 --default
gem install bundler passenger --no-ri --no-rdoc
passenger-install-nginx-module
