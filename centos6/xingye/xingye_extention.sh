#!/bin/bash

cd `dirname $0`
echo `pwd`

server_ip=$1
cluster_name=$2
ambari_user=$3

sh ssh_without_passwod.sh $ambari_user

cd -