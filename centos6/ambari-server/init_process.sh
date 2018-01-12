#!/bin/bash
#$1 -- ambari-server的IP

baseurl=$1
params_file=$2

#ambari-server主机参数优化（包括THP、防火墙等）
./init_centos6.sh

#其它主机上的参数优化
./init_all_hosts.sh $baseurl $params_file

#将ambari-server主机上的公钥加入到authorized_keys文件
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

