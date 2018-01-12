#!/bin/bash

local_hn=`hostname`

#修改本机/etc/hosts文件
if [ -f host_old ];then
  cat host_old | while read line;do
    sed -i "s/$line/""/g" /etc/hosts
  done
  rm -rf host_old
fi

#删除/etc/hosts文件内已有IP或hostname与host文件需要添加的IP或hostname重复的映射
cat host | while read line; do
  ipaddr=`echo $line|awk '{print $1}'`
  hns=`echo $line|awk '{print $2}'`
  cat /etc/hosts | while read line; do
    ipaddr_host=`echo $line|awk '{print $1}'`
    hns_host=`echo $line|awk '{print $2}'`
    if [ "$ipaddr" = "$ipaddr_host" ] || [ "$hns" = "$hns_host" ];then
      sed -i "s/$line//g" /etc/hosts
    fi
  done
done

#删除/etc/hosts文件的空行
sed -i "/^$/d" /etc/hosts

cat host >> /etc/hosts
cp host host_old

#分发本机hosts文件到其它主机
passwd_file=ip.txt

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