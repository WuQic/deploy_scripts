#!/bin/bash

baseurl=$1

#安装jdk
if [ ! -d "/usr/local/jdk18" ];then
pushd /usr/local/
packagename="jdk-8u91-linux-x64.tar.gz"
wget $baseurl/SG/centos6/1.0/${packagename}
echo "tar -zxf ${packagename}  ..."
tar -zxf ${packagename}
rm -rf jdk18
mv jdk1.8.0_91 jdk18
rm -rf ${packagename}
popd 
fi

#添加jdk环境变量
res=`grep "export JAVA_HOME=" /etc/profile`
if [ "$res" = "" ]
   then
	 echo 'export JAVA_HOME=/usr/local/jdk18' >> /etc/profile
	 echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
fi

source /etc/profile
