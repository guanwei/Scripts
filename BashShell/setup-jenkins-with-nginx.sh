#!/usr/bin/env bash

set -e
[ -n "$DEBUG" ] && set -x

# check for root user
if [ "$(id -u)" -ne 0 ] ; then
    echo "You must run this script as root. Sorry!"
    exit 1
fi

# if Amazon
if [ -n "$(uname -r | grep 'amzn')" ]; then
    yum -y install nginx tomcat8
    if [ ! -f /var/lib/tomcat8/webapps/jenkins.war ]; then
        wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war -P /var/lib/tomcat8/webapps/
    fi

    if [ -z "$(grep -E 'location\s+\^~\s+/jenkins/\s+{' /etc/nginx/nginx.conf)" ]; then
        sed -i -r '/# redirect server error pages to the static page \/40x.html/i\
        location ^~ /jenkins/ { \
            proxy_pass http://127.0.0.1:8080; \
            proxy_set_header Host \$host; \
            proxy_set_header X-Real-IP \$remote_addr; \
            proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for; \
        } \
        ' /etc/nginx/nginx.conf
    fi

    chkconfig tomcat8 on
    service tomcat8 start
    chkconfig nginx on
    service nginx start

    echo "=============================="
    echo "jenkins administrator password"
    echo "=============================="
    cat /usr/share/tomcat8/.jenkins/secrets/initialAdminPassword
fi

# if RedHat/CentOS
if [ -n "$(uname -r | grep 'el')" ]; then
    cat > /etc/yum.repos.d/nginx.repo << EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/rhel/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF
    yum install -y nginx tomcat >/dev/null
    if [ ! -f /var/lib/tomcat/webapps/jenkins.war ]; then
        wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war -P /var/lib/tomcat/webapps/
    fi
    if [ -z "$(grep -E 'location\s+\^~\s+/jenkins/\s+{' /etc/nginx/conf.d/default.conf)" ]; then
        sed -i -r '/error_page\s+404\s+\/404.html;/i\
    location ^~ /jenkins/ { \
        proxy_pass http://127.0.0.1:8080; \
        proxy_set_header Host \$host; \
        proxy_set_header X-Real-IP \$remote_addr; \
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \
    } \
        ' /etc/nginx/conf.d/default.conf
    fi

    chkconfig tomcat on
    service tomcat start
    chkconfig nginx on
    service nginx start

    echo "=============================="
    echo "jenkins administrator password"
    echo "=============================="
    cat /usr/share/tomcat/.jenkins/secrets/initialAdminPassword
fi

# config selinux
if [ "$(getenforce)" == "Enforcing" ]; then
    setsebool -P httpd_can_network_relay 1
fi
