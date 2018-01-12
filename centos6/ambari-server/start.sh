#!/bin/bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                          帮助文档"
  echo "     -ambari_ip <ip>                (必填)ambari-server所在主机的IP"
  echo "     -http_port <port>              http服务端口号，如果不填写,则该参数默认设置为: 81"
  echo "     -cluster_name <name>           集群名称，如果不填写,则该参数默认设置为: sugo_cluster"

  echo "            以下参数选填，根据实际需求确定，输入格式例：-skip_ambari："
  echo "     -skip_ambari                   是否安装ambari-server，若不需要安装，则添加该参数，如: -skip_ambari  需要安装则不添加该参数"
  echo "     -csv                           选择自定义csv格式的文件或按照默认来安装服务，默认时不填写该参数"
  echo "     -skip_createdir                不创建元数据存储目录"
  echo "     -skip_ssh                      不安装ssh免密码"
  echo "     -skip_jdk                      不安装jdk"
  echo "     -skip_cluster_services         不创建集群且不安装服务，部署过程仅进行到ambari-server安装完成"
}

#cd `dirname $0`
http_port=81
ambari_ip=""
cluster_name="sugo_cluster"

skip_ambari=""
csv=""
hostname="skip_hostname"
skip_http=0
skip_createdir=0
skip_ssh=1
skip_jdk=0
skip_cluster_services=0

#while read line
#do
#hn=`echo $line|awk '{print $1}'`
#pw=`echo $line|awk '{print $2}'`
#server_hn=`hostname`
#
#if [ "$hn" = "$server_hn" ];then
#server_password="$pw"
#fi
#done<ip.txt
server_hn=`hostname`

while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -ambari_ip) ambari_ip=$2 && shift 2;;
       -http_port) http_port=$2 && shift 2;;
       -cluster_name) cluster_name=$2 && shift 2;;
       -skip_ambari) skip_ambari=1 && shift ;;
       -csv) csv=1 && shift ;;
       -skip_http) skip_http=1 && shift ;;
       -skip_createdir) skip_createdir=1 && shift ;;
       -skip_ssh) skip_ssh=1 && shift ;;
       -skip_jdk) skip_jdk=1 && shift ;;
       -skip_cluster_services) skip_cluster_services=1 && shift ;;
    esac
done

if [ "$http_port" -eq 0 ]; then
    echo "-http_port is required!"
    exit 1
fi

if [ "$ambari_ip" = "" ]; then
    echo "-ambari_ip is required!"
    exit 1
fi

if [ $skip_cluster_services -eq 0 ]; then
    if [ "$cluster_name" = "" ]; then
        echo "-cluster_name is required!"
        exit 1
    fi

fi

if [ "$skip_ambari" = "" ];then
  ambari_server_dir="/var/lib/ambari-server"
  if [ -d "$ambari_server_dir" ];then
    echo "/var/lib/ambari-server目录已存在，请确认是否已经安装过ambari-server！如果安装过ambari，请先彻底删除相关目录！如果无需>重复安装，请加上参数: -skip_ambari "
    exit 1
  fi
fi

#安装yum源
if [ $skip_http -eq 0 ]
  then
    ./sugo_yum_inst.sh $http_port
      echo "~~~~~~~~~~~~httpd installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~~http server skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#修改astro包名
astro_package=`ls /var/www/html/sugo_yum/SG/centos6/1.0/ | grep sugo-analytics*`
echo $astro_package
cd /var/www/html/sugo_yum/SG/centos6/1.0/
mv $astro_package sugo-analytics-SAAS.tar.gz
cd -

#http_port=`cat /etc/httpd/conf/httpd.conf |grep "Listen " |grep -v "#" |awk '{print $2}'`
baseurl=http://$ambari_ip:$http_port/sugo_yum

#相关依赖并开启ntpd
if [ $skip_ssh -eq 0 ]; then
    ./install_dependencies.sh
else
    ./install_dependencies_without_pw.sh
fi
echo "~~~~~~~~~~~~replies installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#分发hosts文件
if [ $skip_ssh -eq 0 ]
  then
    ./configure_hosts.sh
    echo "~~~~~~~~~~~~hosts file success coped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~~scp hosts file skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#创建元数据存储目录
if [ $skip_createdir -eq 0 ]
  then
    ./create_datadir.sh
    echo "~~~~~~~~~~~datadir success created~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~create datadir skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#初始化主机
./init_process.sh $baseurl
echo "~~~~~~~~~~~inited centos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#修改ambari-server节点的hostname
#if [ $skip_hostname != "skip_hostname" ]
#  then
#    hostname $hostname
#    sed -i "s/HOSTNAME=.*/HOSTNAME=${hostname}/g" /etc/sysconfig/network
#    #按照ip.txt内的域名修改其它所有节点的hostname
#    ./hostname.sh ip.txt
#    cat new_hostname >> /etc/hosts
#    echo "~~~~~~~~~~~hostname success changed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#  else
#    echo "~~~~~~~~~~~change hostname skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#fi

#配置ssh免密码登录
if [ $skip_ssh -eq 0 ]
  then
    ./ssh-inst.sh $baseurl ip.txt
    echo "~~~~~~~~~~~ssh-password-less configured~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~ssh-password-less skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#安装jdk
if [ $skip_jdk -eq 0 ]
  then
    ./jdk-inst.sh $baseurl host
    echo "~~~~~~~~~~~jdk success installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~jdk install skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#判断ambari-server是否已经安装，如果没有则安装
if [ "$skip_ambari" = "" ];then
  ambari_server_dir="/var/lib/ambari-server"
  if [ ! -d "$ambari_server_dir" ];then
    #安装ambari-server
    ./ambari_server_inst.sh $baseurl
  fi
fi

#判断是通过csv格式自定义服务安装的位置还是按照默认安装服务
rm -rf ../service/hosts.json
cd ../conf/
if [ "$csv" = "" ];then
  cp hosts.json ../service/
else
  python csv_json.py hosts.csv
  cp hosts_csv.json ../service/hosts.json
fi
cd -  

#创建集群并安装服务
if [ $skip_cluster_services -eq 0 ]
  then

    cd ../service
    echo `pwd`
    echo "http_port:$http_port, server_ip:$ambari_ip, cluster_name:$cluster_name, baseurl:$baseurl"
    if [ "$csv" = "" ];then
        source install.sh -http_port $http_port -server_IP $ambari_ip -cluster_name $cluster_name
    else
        source install.sh -http_port $http_port -server_IP $ambari_ip -cluster_name $cluster_name -csv
    fi
    cd -
fi
