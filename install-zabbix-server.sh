#!/usr/bin/env bash
#Disable SELinux
enforceStatus=getenforse
if [ "$enforceStatus" != "Permissive" ]; then
setenforce 0
fi
#Install the repository configuration package
#rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all
#Install Zabbix server, frontend, agent, database, httpd
yum install zabbix-server-mysql -y
yum install zabbix-web-mysql -y
yum install zabbix-agent -y
yum install mariadb mariadb-server -y
yum install httpd -y
#Start and add to autostart DB mariadb
systemctl start mariadb
systemctl enable mariadb.service
#Create DB (example1)
mysql -uroot <<EOF
create database zabbix character set utf8 collate utf8_bin;
create user 'zabbix'@'localhost' identified by 'zabbix';
grant all privileges on zabbix.* to 'zabbix'@'localhost';
EOF
#Import initial schema and data
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql zabbix
#Configure the database for Zabbix server
echo DBPassword=zabbix >> /etc/zabbix/zabbix_server.conf
#Configure frontend 
sed -i 's:# php_value date.timezone.*:php_value date.timezone America\/Argentina\/Buenos_Aires:g' /etc/httpd/conf.d/zabbix.conf;
#Start zabbix server processes start at system boot
systemctl restart zabbix-server
systemctl enable zabbix-server
#Start httpd processes start at system boot
systemctl restart httpd
systemctl enable httpd
#Start zabbix-agent processes start at system boot
systemctl restart zabbix-agent
systemctl enable zabbix-agent
#Add permissions to irewall
firewall-cmd --permanent --add-port=10050/tcp
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
