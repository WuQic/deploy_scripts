#!/bin/bash

local_hn=`hostname`

#分发本机hosts文件到其它主机
passwd_file=$1

cat $passwd_file | while read line;
do
pw=`echo $line|awk '{print $1}'`
hn=`echo $line|awk '{print $2}'`
if [ "$hn" != "$local_hn" ];then
/usr/bin/expect <<-EOF
set timeout 100000
spawn scp -r /etc/hosts root@$hn:/etc/
	expect {
	"*yes/no*" { send "yes\n"
	expect "*assword:" { send "$pw\n" } }
	"*assword:" { send "$pw\n" }
	"*]#*"	
	}
	expect "*]#*"
EOF
fi
done