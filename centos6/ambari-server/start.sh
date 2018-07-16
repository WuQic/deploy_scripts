#!/bin/bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                          Documentation"
  echo "     -ambari_ip <ip>                (required) The IP of Ambari-Server"
  echo "     -http_port <port>              Http port, default: 81"
  echo "     -cluster_name <name>           The name of cluster, default: sugo_cluster"
  echo "     -new_hostname                  Change hostname"
  echo "     -skip_ambari                   If installed ambari-server, you can add the parameter to skip the install of ambari-server"
  echo "     -skip_http                     Add the parameter if the httpd service installed before and you do not want change http port"
  echo "     -skip_createdir                Add the parameter if the directories created"
  echo "     -skip_ssh                      Add the parameter if the password-less SSH configured"
  echo "     -skip_jdk                      Add the parameter if jdk installed"
  echo "     -skip_cluster_services         Just install ambari-server, don't create the cluster,and don't install service by the scripts"
  echo "     -skip_hadoop                   Do not install hadoop"
  echo "     -skip_kafka                    Do not install kafka"
}

#cd `dirname $0`
http_port=81
ambari_ip=""
cluster_name="sugo_cluster"

skip_ambari=""
csv=""
new_hostname="skip_hostname"
skip_http=0
skip_createdir=0
skip_ssh=0
skip_jdk=0
skip_cluster_services=0
skip_hadoop=""
skip_kafka=""

#校验license是否存在
ambari_license=`cat license`
license_length=`expr length $ambari_license`
if [ $license_length -eq 15 ];then
        echo "license is not exist...please check it and retry..."
        exit 1        
fi

#校验host是否存在大写


if [ "$skip_ssh" -eq 0 ]; then
  params_file="ip.txt"
else
  params_file="host"
fi

while read line
do
pw=`echo $line|awk '{print $1}'`
hn=`echo $line|awk '{print $2}'`
server_hn=`hostname`

if [ "$hn" = "$server_hn" ];then
server_password="$pw"
fi
done<$params_file


while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -ambari_ip) ambari_ip=$2 && shift 2;;
       -http_port) http_port=$2 && shift 2;;
       -cluster_name) cluster_name=$2 && shift 2;;
       -new_hostname) new_hostname="new_hostname" && shift ;;
       -skip_ambari) skip_ambari=1 && shift ;;
       -skip_http) skip_http=1 && shift ;;
       -skip_createdir) skip_createdir=1 && shift ;;
       -skip_ssh) skip_ssh=1 && shift ;;
       -skip_jdk) skip_jdk=1 && shift ;;
       -skip_cluster_services) skip_cluster_services=1 && shift ;;
       -skip_hadoop) skip_hadoop=1 && shift ;;
       -skip_kafka) skip_kafka=1 && shift ;;
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
    echo "The directory /var/lib/ambari-server exists, make sure you never installed ambari-server. delete the directory or add the parameter( -skip_ambari ) if you have installed ambari-server"
    exit 1
  fi
fi

cluster_host1=`cat host | sed -n "1p" |awk '{print $2}'`
cluster_host2=`cat host | sed -n "2p" |awk '{print $2}'`
cluster_host3=`cat host | sed -n "3p" |awk '{print $2}'`
sed -i "s/host1/$cluster_host1/g" ../conf/hosts.csv
sed -i "s/host2/$cluster_host2/g" ../conf/hosts.csv
sed -i "s/host3/$cluster_host3/g" ../conf/hosts.csv
if [ -f host_old ]; then
  new_cluster_host1=`cat host | sed -n "1p" |awk '{print $2}'`
  new_cluster_host2=`cat host | sed -n "2p" |awk '{print $2}'`
  new_cluster_host3=`cat host | sed -n "3p" |awk '{print $2}'`
  old_cluster_host1=`cat host_old | sed -n "1p" |awk '{print $2}'`
  old_cluster_host2=`cat host_old | sed -n "2p" |awk '{print $2}'`
  old_cluster_host3=`cat host_old | sed -n "3p" |awk '{print $2}'`
  if [ "$new_cluster_host1" != "$old_cluster_host1" ]; then
    sed -i "s/$old_cluster_host1/$new_cluster_host1/g" ../conf/hosts.csv
  fi
  if [ "$new_cluster_host2" != "$old_cluster_host2" ]; then
    sed -i "s/$old_cluster_host1/$new_cluster_host2/g" ../conf/hosts.csv
  fi
  if [ "$new_cluster_host3" != "$old_cluster_host3" ]; then
    sed -i "s/$old_cluster_host3/$new_cluster_host3/g" ../conf/hosts.csv
  fi
fi

#安装yum源
if [ $skip_http -eq 0 ]
  then
    ./sugo_yum_inst.sh $http_port
    echo "~~~~~~~~~~~~httpd installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    http_port_status=`netstat -ntlp | grep $http_port`
    if [ "$http_port_status" = "" ];then
      echo "please start httpd and add -http_port <port> after start.sh~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      exit 1
    else
      if [ ! -d "/var/www/html/sugo_yum" ]; then
        echo "directory /var/www/html/sugo_yum is not exists, make sure your httpd service available!~~~~~~"
        exit 1
      fi
      echo "~~~~~~~~~~~~http server skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    fi
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
    ./install_dependencies.sh $params_file
else
    ./install_dependencies_without_pw.sh $params_file
fi
echo "~~~~~~~~~~~~dependencies installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#分发hosts文件
if [ $skip_ssh -eq 0 ]
  then
    ./configure_hosts.sh $params_file
    echo "~~~~~~~~~~~~hosts file success coped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
else
    echo "~~~~~~~~~~~~scp hosts file skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#创建数据存储目录
if [ $skip_createdir -eq 0 ]; then
        ./create_datadir.sh $params_file
    echo "~~~~~~~~~~~datadir success created~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
else
    echo "~~~~~~~~~~~create datadir skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#初始化主机
./init_process.sh $baseurl $params_file
echo "~~~~~~~~~~~init centos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# 修改ambari-server节点的hostname
if [ $new_hostname = "new_hostname" ]
 then
   hostname $hostname
   sed -i "s/HOSTNAME=.*/HOSTNAME=${hostname}/g" /etc/sysconfig/network
   #按照ip.txt内的域名修改其它所有节点的hostname
   cat host >> /etc/hosts
   ./hostname.sh ip.txt
   echo "~~~~~~~~~~~hostname success changed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
 else 
   echo "~~~~~~~~~~~change hostname skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#配置ssh免密码登录
if [ $skip_ssh -eq 0 ]
  then
    ./ssh-inst.sh $baseurl $params_file
    echo "~~~~~~~~~~~ssh-password-less configured~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~ssh-password-less skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#安装jdk
if [ $skip_jdk -eq 0 ]
  then
    ./jdk-inst.sh $baseurl $params_file
    echo "~~~~~~~~~~~jdk success installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~jdk install skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#判断ambari-server是否已经安装，如果没有则安装
if [ "$skip_ambari" = "" ];then
  ambari_server_dir="/var/lib/ambari-server"
  if [ ! -d "$ambari_server_dir" ];then
    #安装ambari-server
    echo "~~~~~~~~~~~~installing ambari-server~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ./ambari_server_inst.sh $baseurl
  fi
fi

#判断是通过csv格式自定义服务安装的位置还是按照默认安装服务
rm -rf ../service/host_*
cd ../conf/
  if [ "$skip_hadoop" = "" ];then
    python csv_json.py hosts.csv KAFKA_SUGO GATEWAY_SUGO DRUIDIO_SUGO ASTRO_SUGO
    cp hostbeforhdfs.json ../service/host_until_hdfs.json
    cp hostafterhdfs.json ../service/host_after_hdfs.json
    if [ "$skip_kafka" != "" ];then
      python csv_json.py hosts.csv GATEWAY_SUGO DRUIDIO_SUGO ASTRO_SUGO
      cp hostbeforhdfs.json ../service/host_until_hdfs.json
      cp hostafterhdfs.json ../service/host_after_hdfs.json
    fi
  else
    mv ../conf/hadoop.config.xml ../service/changed_configurations/
    python csv_json_withouthadoop.py hosts.csv POSTGRES_SUGO REDIS_SUGO ZOOKEEPER_SUGO KAFKA_SUGO GATEWAY_SUGO DRUIDIO_SUGO ASTRO_SUGO
    cp hosts_csv.json ../service/
    if [ "$skip_kafka" != "" ];then
      python csv_json_withouthadoop.py hosts.csv POSTGRES_SUGO REDIS_SUGO ZOOKEEPER_SUGO GATEWAY_SUGO DRUIDIO_SUGO ASTRO_SUGO
      cp hosts_csv.json ../service/
    fi
  fi
cd -

#创建集群并安装服务
if [ $skip_cluster_services -eq 0 ]
  then

    cd ../service
    echo `pwd`
    echo "http_port:$http_port, server_ip:$ambari_ip, cluster_name:$cluster_name, baseurl:$baseurl"
    if [ "$skip_hadoop" = "" ];then
      echo "source install.sh -http_port $http_port -server_IP $ambari_ip -cluster_name $cluster_name "
      source install.sh -http_port $http_port -server_IP $ambari_ip -cluster_name $cluster_name
    else
      echo "source install.sh -http_port $http_port -server_IP $ambari_ip -cluster_name $cluster_name -skip_hadoop"
      source install.sh -http_port $http_port -server_IP $ambari_ip -cluster_name $cluster_name -skip_hadoop
    fi
    cd -
fi
