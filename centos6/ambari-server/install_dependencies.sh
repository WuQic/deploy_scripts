#!/bin/bash

params_file=$1

#ambari-server主机安装相关软件及http服务
yum install -y wget ntp openssh-clients expect

cat $params_file |while read line;
do
pw=`echo $line|awk '{print $1}'`
hn=`echo $line|awk '{print $2}'`
local_hn=`hostname`

if [ "$hn" != "$local_hn" ];then
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $hn
    expect {
    "*yes/no*" { send "yes\n"
    expect "*assword:" { send "$pw\n" } }
    "*assword:" { send "$pw\n" }
        "*]#*"
    { send "yum install -y wget ntp openssh-clients\n" }
        "*]#*"
    { send "service ntpd start\n" }
        "*]#*"
    }
        expect "*#*"
    send "yum install -y wget ntp openssh-clients\n"
        expect "*]#*"
    send "service ntpd start\n"
        expect "*]#*"
EOF
fi
done
