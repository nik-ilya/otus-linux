#!/bin/bash

cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service

sed -i 's/sysconfig\/httpd/sysconfig\/httpd-\%I/g' /etc/systemd/system/httpd@.service

cat > /etc/sysconfig/httpd-first <<EOF
OPTIONS=-f conf/first.conf
EOF

cat > /etc/sysconfig/httpd-second <<EOF
OPTIONS=-f conf/second.conf
EOF

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf

sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/second.conf
echo "PidFile /var/run/httpd-first.pid" >> /etc/httpd/conf/first.conf
echo "PidFile /var/run/httpd-second.pid" >> /etc/httpd/conf/second.conf

systemctl start httpd@first
systemctl start httpd@second
