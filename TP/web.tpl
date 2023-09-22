#!/bin/bash
export HTTP_PROXY=http://${SQUID_IP}:3180
export HTTP_PROXY=http://${SQUID_IP}:3180

yum update	
yum install -y httpd
systemctl enable --now httpd

cat /etc/hostname > tee /var/www/html/index.html

exit;
