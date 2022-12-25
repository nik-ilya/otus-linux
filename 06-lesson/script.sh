#!/bin/bash

sudo -i
cd ~

# install new packets
yum install -y \
    redhat-lsb-core \
    wget \
    rpmdevtools \
    rpm-build \
    createrepo \
    yum-utils \
    gcc

# download RPM packet NGINX
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm

# download OPENSSL
wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1s.tar.gz
mkdir /root/openssl-1.1.1s
tar -xvf /root/openssl-1.1.1s.tar.gz

# install packets
yes | yum-builddep /root/rpmbuild/SPECS/nginx.spec


# edit config NGINX
sed -i 's@index.htm;@index.htm;\n        autoindex on;@g' /root/rpmbuild/SOURCES/nginx.vh.default.conf
sed -i 's@--with-ld-opt="%{WITH_LD_OPT}" @--with-ld-opt="%{WITH_LD_OPT}" \\\n    --with-openssl=/root/openssl-1.1.1s @g' /root/rpmbuild/SPECS/nginx.spec

# assembly RPM package
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec

# install my new package
yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm

# run
systemctl enable nginx
systemctl start nginx

#--------------------------------------------------------
# create new repo

mkdir /usr/share/nginx/html/repo

cp /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
wget https://downloads.percona.com/downloads/percona-release/percona-release-1.0-6/redhat/percona-release-1.0-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

# initialize repo
createrepo /usr/share/nginx/html/repo/

# reload NGINX
nginx -t
nginx -s reload

cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF

# check
yum list | grep otus

# install persona
yum install percona-release -y


