#!/usr/bin/env bash
setenforce 0
timedatectl set-timezone Asia/Tokyo
hostnamectl set-hostname dev.centos7.com
uname -a

yum -y install git
yum -y install wget
yum -y install vim
yum -y install curl
yum -y install sysstat
yum -y install unzip
yum -y install mlocate
yum -y install iotop
yum -y install net-tools
yum -y install lsof
yum -y install glibc-langpack-ja
yum -y install bash-completion

localectl set-locale LANG=ja_JP.UTF-8
source /etc/locale.conf
echo $LANG

wget https://github.com/terralinux/systemd/raw/master/src/systemctl-bash-completion.sh -O /etc/bash_completion.d/systemctl-bash-completion.sh

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

# chrony stop
systemctl stop chronyd
systemctl disable chronyd

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

cp -p /etc/sysstat/sysstat /etc/sysstat/sysstat.org
cp -p /etc/sysstat/sysstat /etc/sysstat/sysstat_$(date +"%Y%m%d")
sed -i 's/HISTORY=7/HISTORY=28/g' /etc/sysstat/sysstat
sed -i 's/COMPRESSAFTER=10/COMPRESSAFTER=31/g' /etc/sysstat/sysstat

systemctl restart sysstat

# SELinux disable
cp -p /etc/sysconfig/selinux ~/BACKUP_$(date +%Y%m%d)/selinux_$(date +%Y%m%d)
cp -p /etc/selinux/config ~/BACKUP_$(date +%Y%m%d)/config_$(date +%Y%m%d)
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
diff -s ~/BACKUP_$(date +%Y%m%d)/selinux_$(date +%Y%m%d) /etc/sysconfig/selinux
echo "-------------------------------------"
diff -s ~/BACKUP_$(date +%Y%m%d)/config /etc/selinux/config

# systemd log level, rsyslog log level
cp -p /etc/systemd/system.conf /etc/systemd/system.conf.org
cp -p /etc/systemd/system.conf /etc/systemd/system.conf_$(date +%Y%m%d)
sed -i 's/#LogLevel=info/LogLevel=notice/g' /etc/systemd/system.conf
systemd-analyze set-log-level notice
systemctl daemon-reexec

cp -p /etc/systemd/journald.conf /etc/systemd/journald.conf.org
cp -p /etc/systemd/journald.conf /etc/systemd/journald.conf_$(date +%Y%m%d)
sed -i 's/#RateLimitIntervalSec=30s/RateLimitIntervalSec=0/g' /etc/systemd/journald.conf

cp -p /etc/rsyslog.conf /etc/rsyslog.conf.org
cp -p /etc/rsyslog.conf /etc/rsyslog.conf_$(date +%Y%m%d)
echo "# Rate Limit" >> /etc/rsyslog.conf
echo '$imjournalRatelimitInterval 0' >> /etc/rsyslog.conf

echo 'if $programname == "systemd" and ($msg contains "Starting Session" or $msg contains "Started Session" or $msg contains "Created slice" or $msg contains "Starting User" or $msg contains "Removed slice" or $msg contains "Stopping User") then stop' >> /etc/rsyslog.d/ignore-systemd-session-slice.conf
echo -n 'if $programname == "systemd" and (\ $msg contains "Closed D-Bus" \
or $msg contains "Closed Multimedia System" \
or $msg contains "Closed REST API socket" \
or $msg contains "Created slice" \
or $msg contains "Listening on Multimedia System" \
or $msg contains "Listening on REST" \
or $msg contains "Listening on D-Bus"\
or $msg contains "Reached target" \
or $msg contains "Removed slice" \
or $msg contains "session-" \
or $msg contains "Started D-Bus" \
or $msg contains "Started Session" \
or $msg contains "Started User" \
or $msg contains "Starting D-Bus" \
or $msg contains "Starting Exit" \
or $msg contains "Starting Session" \
or $msg contains "Starting User" \
or $msg contains "Stopped Session" \
or $msg contains "Stopped target" \
or $msg contains "Stopped User" \
or $msg contains "Stopping Session" \
or $msg contains "Stopping User" \
) then stop' >> /etc/rsyslog.d/ignore-systemd-session-slice.conf

systemctl restart systemd-journald
systemctl restart rsyslog.service

# cloud-init
sed -i 's/- set_hostname/# - set_hostname/g' /etc/cloud/cloud.cfg
sed -i 's/- update_hostname/# - update_hostname/g' /etc/cloud/cloud.cfg
sed -i 's/- update_etc_hosts/# - update_etc_hosts/g' /etc/cloud/cloud.cfg
sed -i 's/- locale/# - locale/g' /etc/cloud/cloud.cfg
sed -i 's/- timezone/# - timezone/g' /etc/cloud/cloud.cfg
sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg

# swap
chmod +x /etc/rc.d/rc.local

dd if=/dev/zero of=/swap bs=1M count=4096

echo -e -n 'mkswap /swap\n' >> /etc/rc.d/rc.local
echo -e -n 'swapon /swap\n' >> /etc/rc.d/rc.local
echo -e -n 'chmod 600 /swap\n' >> /etc/rc.d/rc.local

echo "vm.swappiness=0" >> /etc/sysctl.conf
sysctl -p

# mlocate update
updatedb

# OS Update
yum -y update

# reboot
shutdown -r now
