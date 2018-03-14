#!/bin/bash

httpd_port=$1
server_IP=$2
cluster_name=$3


curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://$server_IP:8080/api/v1/clusters/$cluster_name/services/HDFS_SUGO > /dev/null 2>&1

curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://$server_IP:8080/api/v1/clusters/$cluster_name/services/REDIS_SUGO > /dev/null 2>&1

curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://$server_IP:8080/api/v1/clusters/$cluster_name/services/ZOOKEEPER_SUGO > /dev/null 2>&1

curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://$server_IP:8080/api/v1/clusters/$cluster_name/services/POSTGRES_SUGO > /dev/null 2>&1

curl -u admin:admin -H "X-Requested-By: ambari" -X DELETE  http://$server_IP:8080/api/v1/clusters/$cluster_name/services/AMBARI_METRICS > /dev/null 2>&1

#创建集群
curl -u admin:admin -H "X-Requested-By: ambari" -X POST -d '{"Clusters": {"version" : "SG-1.0"}}' http://$server_IP:8080/api/v1/clusters/$cluster_name

#更新基础url
curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d '{"Repositories":{"base_url":"http://'$server_IP':'$httpd_port'/sugo_yum/SG/centos6/1.0/"}}' http://$server_IP:8080/api/v1/stacks/SG/versions/1.0/operating_systems/redhat6/repositories/SG-1.0

#安装ambari-agent
cd ../ambari-agent
python install_agent.py $cluster_name $server_IP "host"


#判断agent是否已经安装完成并启动
yum install -y lsof
printf "waiting for ambari-agent to start"
x=0
while true;do
res=`lsof -n -i:8441 | grep $server_IP |awk '{print $9}' | wc -l`
num_host=`cat ../ambari-agent/host | wc -l`
  if [ $res != $[$num_host + 1] ];then
    sleep 3
    x=$[$x+1]
    if [ $x -lt 15 ];then
        printf "."
        continue
    else
        echo -e "\n==========Timeout==========\nThe start of ambari-agent failed, please cancel the start.sh and check the configurations ,run start.sh again!"
        continue
    fi
  else
    break
  fi
done
sleep 3
echo ""

#注册ambari-agent
python regist_agent.py $cluster_name $server_IP "host"
cd -

#修改pg数据库
curl -u admin:admin -H "X-Requested-By: ambari" -X POST -d '{
    "mainConfigHistoryController-pagination-displayLength-admin": "\"10\"",
        "user-pref-admin-dashboard": "{\"dashboardVersion\": \"new\",\"visible\": [],\"hidden\": [],\"threshold\": {\"1\": [80,90],\"2\": [85,95],\"3\": [90,95],\"4\": [80,90],\"5\": [1000,3000],\"6\": [],\"7\": [],\"8\": [],\"9\": [],\"10\": [],\"11\": [],\"12\": [],\"13\": [70,90],\"14\": [150,250],\"15\": [3,10],\"16\": [],\"17\": [70,90],\"18\": [],\"19\": [50,75],\"20\": [50,75],\"21\": [85,95],\"22\": [85,95],\"23\": [],\"24\": [75,90]}}",
    "admin-settings-show-bg-admin": "true",
        "CLUSTER_CURRENT_STATUS": "\"N4IgxgNgrgzgLgUwE4DkCGBbBIBcIZQDmA9gPoAK0MAggJIgA04ViSAynGoriACICiAMWoBVADIAVRiADuASwBeaJABMAwsQB2cJMQgRk6LDzmb4afcg3bdlpNIjEwFlQCNcoNAAcvH8FoAzOUIYXABtAF0AXyZaM047P1NzSxU2ZAA3OTAEIwRQnEiYkGoVFQAJYngPYtK0zOzsHGBigHU5FUIEOHalVRqmAGlkV2Qq3uUVAZAAJQQ0GBhgzQBZBdZpuvSwKCQ5OABPTbLqAyQ4XgQgzX25LT8wLURtGuLy4IALagy0OQg0Vx/fYHCb9ZrFGYrd6EL4/P4AoGHUFTcFMOrlNAyACOHDQmjcIMUk2mcwwxAyCAx2Nx+NchL6KJaaLAcDkP0QVJxnFp9OJqNm1GhsN+/0BEGByJJeggrjQYAA1kLviKEeKkUSwUyQGtTKUMKZcQrqPiRF5CEg0ComlrhkhRroYLw5DAAQZpnAML5+e1Ot1+Cp9tMdZpeAsPq5iJMfV04DAAGpyBAyPywZAAWi8SCuact+s0aZUYYjfNAhZg4cjqjjyCW9zwmiT0iyS1cbsKESYHw6Vs04Q7IDgHyz5b0jJAAEZwgAOAAMDAAnDP+wAmacAVgXa/7AGZwovN/2ACzTueL/tr8LjmfXhjb69LpgANj7TAA7C+QFOP/OP1ff5P2yYcdV0Aidd0KV9TwfCdj0Kcc1znZcEP7eDwm3BgrxQ59QPHd8IKglCvxwn9CgQhhXy3JhlxncIyIolcALCKcN3nSiQGXECmJYtjl3AyIqNgsIKIXJcojEsSgA\"",
    "admin-settings-timezone-admin": "\"-480-480|Antarctica\""
}' http://$server_IP:8080/api/v1/persist/

curl -u admin:admin -H "X-Requested-By: ambari" -X PUT -d ' {"Clusters":{"provisioning_state":"INSTALLED"}}'  http://$server_IP:8080/api/v1/clusters/$cluster_name

#应用配置（cluster-env）
curl -u admin:admin -H "X-Requested-By: ambari" -i -X POST -d '{"type": "cluster-env", "tag": "version2", "properties" : {"security_enabled": "false", "managed_hdfs_resource_property_names": "", "override_uid": "true", "ignore_groupsusers_create": "false", "smokeuser_keytab": "/etc/security/keytabs/smokeuser.headless.keytab", "kerberos_domain": "EXAMPLE.COM", "fetch_nonlocal_groups": "true", "repo_suse_rhel_template": "[{{repo_id}}]\nname={{repo_id}}\n{% if mirror_list %}mirrorlist={{mirror_list}}{% else %}baseurl={{base_url}}{% endif %}\n\npath=/\nenabled=1\ngpgcheck=0", "user_group": "hadoop", "smokeuser": "ambari-qa", "repo_ubuntu_template": "{{package_type}} {{base_url}} {{components}}"}}' http://$server_IP:8080/api/v1/clusters/$cluster_name/configurations

curl -u admin:admin -H "X-Requested-By: ambari" -i -X PUT -d '{ "Clusters" : {"desired_configs": {"type": "cluster-env", "tag" : "version2" }}}'  http://$server_IP:8080/api/v1/clusters/$cluster_name
