#!/bin/bash

params_file=$1

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


#ambari-server主机安装相关软件及http服务
yum install -y wget ntp openssh-clients expect

cat $params_file |while read line;
do
pw=`echo $line|awk '{print $1}'`
hn=`echo $line|awk '{print $2}'`
hn_alias=`echo $line|awk '{print $3}'`
local_hn=`hostname`

if [ "$hn" != "$local_hn" ] && [ "$hn_alias" != "$local_hn" ];then
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
