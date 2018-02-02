#!/bin/bash


#判断hostname是否符合规则
host_name1=`hostname | cut -d \. -f 3`
host_name2=`hostname | cut -d \. -f 4`

if [ "$host_name1" = "" ];then
  echo "please alter the hostname on domain name format~~~~~~~~~~~~~~~~~~~~~~~~"
fi

if [ ! -z $host_name2 ];then
  echo "please alter the hostname on domain name format~~~~~~~~~~~~~~~~~~~~~~~~"
fi


#判断数据存储目录是否已存在
data1_dir="/data1"
data2_dir="/data2"

if [ -d $data1_dir ] || [ -d $data2_dir ];then
  echo "数据目录/data1或/data2已创建，请确认该目录是否能够用于数据存储，如果可以，请在执行start.sh脚本时添加参数-skip_createdir skip_createdir并手动确认/data1和/data2都已创建"
fi

service_port=(5432 8080 15342 6379 2181 50070 8485 50075 50010 8088 8480 19888 9092 8081 8082 8083 8090 8091 8100 8000 8887)
for port in ${service_port[@]};
do
port1=`netstat -ntlp | grep $port`
if [ "$port1" != "" ];then
  echo "$port端口是否已经被使用？sugo安装的服务中，可能会与该服务产生端口冲突，请修改该端口号或暂停该服务"
fi
done

nginx_port=`netstat -ntlp | grep 80 | grep nginx`
if [ "$nginx_port" = "" ];then
  echo "80端口是否已经被使用？sugo安装的服务中，网关可能会与该服务产生端口冲突，请修改该端口号或暂停该服务"
fi
