#!/bin/bash

yum update
yum install -y squid

rm /etc/squid/squid.conf

cat <<EOF>> /etc/squid/squid.conf
http_access allow all
http_port 3128
EOF

systemctl enable --now squid
