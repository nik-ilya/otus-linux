#!/bin/bash

sudo -i

cat > /etc/sysconfig/watchlog <<EOF
WORD="ALERT"
LOG=/var/log/watchlog.log
EOF

cat > /var/log/watchlog.log <<EOF
bla-bla-bla
ALERT!!!
bla-bla-bla
ALERT!!!
bla-bla-bla
ALERT!!!
bla-bla-bla
ALERT!!!
EOF

cat > /opt/watchlog.sh <<EOF
#!/bin/bash
WORD=\$1
LOG=\$2
DATE=\`date\`
if grep \$WORD \$LOG &> /dev/null
then
    logger "\$DATE: I found word, Master guru!"
else
    exit 0
fi
EOF

chmod +x /opt/watchlog.sh

cat > /etc/systemd/system/watchlog.service <<EOF
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh \$WORD \$LOG
EOF

cat > /etc/systemd/system/watchlog.timer <<EOF
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnActiveSec=30
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
EOF

systemctl enable watchlog.timer
systemctl start watchlog.timer
