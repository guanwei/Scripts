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

ORACLE_JDK_URL="http://download.oracle.com/otn-pub/java/jdk/8u91-b14/jdk-8u91-linux-x64.rpm"
JDK_RPM=${ORACLE_JDK_URL##*/}
rpm -qa | grep java | xargs rpm -e --nodeps
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $ORACLE_JDK_URL
rpm -ivh $JDK_RPM

cat > /etc/profile.d/java.sh <<-EOF
export JAVA_HOME=/usr/java/default
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib
EOF
source /etc/profile

ANDROID_SDK_URL="https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz"
ANDROID_SDK=${ANDROID_SDK_URL##*/}
wget $ANDROID_SDK_URL
tar zxvf $ANDROID_SDK -C /opt/

cat > /etc/profile.d/android.sh <<-EOF
export ANDROID_HOME=/opt/android-sdk-linux
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
EOF
source /etc/profile

android update sdk -u -t platform,platform-tool

#android update sdk -u -t build-tools
#'2- Android SDK Build-tools, revision 24' | grep 'Android SDK Build-tools' |
