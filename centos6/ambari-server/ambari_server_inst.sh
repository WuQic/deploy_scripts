#!/bin/bash

http_port=`cat /etc/httpd/conf/httpd.conf |grep "Listen " |grep -v "#" |awk '{print $2}'`
baseurl=$1
ambari_license_dir=$(cd "$(dirname "$0")";pwd)

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

res=`grep 'ambari_license' /etc/ambari-server/conf/ambari.properties`
if [ "$res" = "" ];then
        echo "ambari_license dir:"$ambari_license_dir
        cat ${ambari_license_dir}'/'license >> /etc/ambari-server/conf/ambari.properties
fi

ambari-server start
