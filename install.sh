#!/bin/bash -x

apt-get update
apt-get install -y build-essential make gcc

curl -s https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest |
    grep "softether-vpnserver.*linux-x64-64bit.tar.gz" |
    cut -d : -f 2,3 |
    tr -d \" |
    wget -O /tmp/softether-vpnserver.tar.gz -i -

tar xfz /tmp/softether-vpnserver.tar.gz -C /usr/local
cd /usr/local/vpnserver
make

chown -R root:root /usr/local/vpnserver

find /usr/local/vpnserver -type f -exec chmod 600 {} \;
find /usr/local/vpnserver -type d -exec chmod 700 {} \;

chmod +x /usr/local/vpnserver/vpncmd
chmod +x /usr/local/vpnserver/vpnserver

cat >/lib/systemd/system/softether.service <<EOF
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!/usr/local/vpnserver/do_not_run

[Service]
Type=forking
TasksMax=16777216
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
KillMode=process
Restart=on-failure

# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=/usr/local/vpnserver
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYSLOG CAP_SETUID

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start softether.service
systemctl enable softether.service
rm -f /tmp/softether-vpnserver.tar.gz
