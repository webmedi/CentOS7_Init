#!/usr/bin/env bash
localectl set-locale LANG=ja_JP.UTF-8
source /etc/locale.conf
echo $LANG
timedatectl set-timezone Asia/Tokyo
hostnamectl set-hostname dev.centos7.com
uname -a
yum -y install git wget vim curl sysstat unzip

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

# sysstat init
systemctl start sysstat
systemctl enable sysstat
mkdir -p ~/BACKUP_$(date +%Y%m%d)
cp -p /etc/cron.d/sysstat ~/BACKUP_$(date +%Y%m%d)/
echo -n '# Run system activity accounting tool every 10 minutes
*/1 * * * * root /usr/lib64/sa/sa1 1 1
# 0 * * * * root /usr/lib64/sa/sa1 600 6 &
# Generate a daily summary of process accounting at 23:53
53 23 * * * root /usr/lib64/sa/sa2 -A' > /etc/cron.d/sysstat
systemctl restart sysstat

# reboot
shutdown -r now
