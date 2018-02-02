#!/bin/bash

http_port=`cat /etc/httpd/conf/httpd.conf |grep "Listen " |grep -v "#" |awk '{print $2}'`
baseurl=$1
cd /etc/yum.repos.d
rm ambari.repo
wget $baseurl/AMBARI-2.2.2.0/centos6/2.2.2.0-0/ambari.repo
sed -i "s/192.168.0.200/`hostname`/" ambari.repo
sed -i "s/81/$http_port/g" ambari.repo
sed -i "s/yum/sugo_yum/g" ambari.repo

yum install ambari-server -y

/usr/bin/expect <<-EOF
set timeout 3000 
spawn ambari-server setup
expect {
        "*(n)?" {send "\n"
        expect {
        "*(1):" { send "3\n"
        expect "JAVA_HOME:" {send "/usr/local/jdk18\n"
        expect "*(n)?" { send "\n" }}
        }}}}
        expect "*]#*"
EOF

#add the license
ambari_license=`cat /etc/ambari-server/conf/ambari.properties | grep "ambari_license"`
if [ "$ambari_license" = "" ];then
  license=`cat license`
  echo "ambari_license=$license" >> /etc/ambari-server/conf/ambari.properties
fi


ambari-server start
