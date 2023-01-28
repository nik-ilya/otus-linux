#!/bin/bash

sudo -i

sed -i 's/#SOCKET/SOCKET/g' /etc/sysconfig/spawn-fcgi
sed -i 's/#OPTIONS/OPTIONS/g' /etc/sysconfig/spawn-fcgi


cat > /etc/systemd/system/spawn-fcgi.service <<EOF
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl enable spawn-fcgi
systemctl start spawn-fcgi
