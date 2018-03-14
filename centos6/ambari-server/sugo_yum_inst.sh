#!/bin/bash

#端口号--$1
http_port=$1

#ambari-server主机安装相关软件及http服务
yum install -y httpd

http_server=`yum list httpd | grep "Installed Packages"`
if [ "$http_server" = "" ];then
    echo 'Installing httpd~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
	yum install -y httpd
else
    echo 'Httpd has been installed before , will change the listen port of /etc/httpd/conf/httpd.conf to '$http_port'~~~'
fi

#修改http端口号
sed -i "s/Listen `cat /etc/httpd/conf/httpd.conf |grep "Listen " |grep -v "#" |awk '{print $2}'`/Listen $http_port/" /etc/httpd/conf/httpd.conf

#创建软连接
cd ../..
yum_direct=`echo $(dirname $(pwd))`
ln -s $yum_direct /var/www/html/


#开启http服务
http_server_status=`ps -ef | grep httpd | grep -v "grep httpd"`
if [ "$http_server_status" = "" ];then
    service httpd start
else
    service httpd restart
fi