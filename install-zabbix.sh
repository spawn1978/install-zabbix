#!/usr/bin/env bash
setenforce 0
#Install the repository configuration package
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
yum clean all
#Install Zabbix server, frontend, agent, database
yum install zabbix-server-mysql -y
yum install zabbix-web-mysql -y
yum install zabbix-agent -y
yum install mariadb-server -y
#Start DB
systemctl start mariadb
#Create DB (example1)
mysql -uroot <<EOF
create database zabbix character set utf8 collate utf8_bin;
create user 'zabbix'@'localhost' identified by 'zabbix';
grant all privileges on zabbix.* to 'zabbix'@'localhost';
EOF
#Create DB (example2)
mysql -u root -e "CREATE DATABASE zabbix; CREATE USER zabbix@localhost identified by 'zabbix'; GRANT ALL ON zabbix.* to zabbix@localhost WITH GRANT OPTION;"
#Import initial schema and data
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql zabbix
#Configure the database for Zabbix server
echo DBPassword=zabbix >> /etc/zabbix/zabbix_server.conf
#Start zabbix server
systemctl start zabbix-server
#Configure frontend
sed -i 's:# php_value date.timezone.*:php_value date.timezone Europe\/Minsk:g' /etc/httpd/conf.d/zabbix.conf;
#Start httpd
systemctl restart zabbix-server zabbix-agent httpd
#Make Zabbix server and agent processes start at system boot
systemctl enable zabbix-server zabbix-agent httpd
