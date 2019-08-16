#!/usr/bin/env bash
localectl set-locale LANG=ja_JP.UTF-8
source /etc/locale.conf
echo $LANG
timedatectl set-timezone Asia/Tokyo
hostnamectl set-hostname dev.centos7.com
uname -a
yum -y install git wget vim curl sar unzip

# vim customize
git clone https://github.com/webmedi/test.git
chmod 700 test/autoVimCustomize.sh
./test/autoVimCustomize.sh
rm -rf rf test

# ntp init
yum -y install ntp
chkconfig ntpd on
cp -p /etc/ntp.conf /etc/ntp.conf_$(date +%Y%m%d)
sed -i 's/server [0-2].centos.pool.ntp.org iburst/server -4 ntp.nict.jp iburst/g' /etc/ntp.conf
sed -i 's/server 3.centos.pool.ntp.org iburst/#server 3.centos.pool.ntp.org iburst/g' /etc/ntp.conf
systemctl restart ntpd
ntpq -p

# reboot
shutdown -r now
