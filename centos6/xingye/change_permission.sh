#!/bin/bash

## 分发到所有机器执行

mkdir -p /opt/apps/
chown -R ambari:ambari /opt/apps
chown -R ambari:ambari /etc/ambari-*
chown -R ambari:ambari /var/lib/ambari-*
chown -R ambari:ambari /var/log/ambari-*
chown -R ambari:ambari /opt/data1
chown -R ambari:ambari /opt/data2

ambari-server status;
if [[ $? -eq 0 ]]; then
    ambari-server stop
    mv /var/log/ambari-server /data1/
    ln -s /data1/ambari-server /var/log/ambari-server
    mv /var/lib/ambari-server /opt/apps/
    ln -s /opt/apps/ambari-server /var/lib/ambari-server
    echo -ne 'y\nambari\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n' | ambari-server setup
    su - ambari -c '/usr/sbin/ambari-server start'
fi

ambari-agent stop
mv /var/log/ambari-agent /data1/
ln -s /data1/ambari-agent /var/log/ambari-agent
mv /var/lib/ambari-agent /opt/apps/
ln -s /opt/apps/ambari-agent /var/lib/ambari-agent

echo 'Defaults    exempt_group = ambari' >> /etc/sudoers
echo 'Defaults    !env_reset,env_delete-=PATH' >> /etc/sudoers
echo 'Defaults: ambari !requiretty' >> /etc/sudoers
echo 'ambari        ALL=(ALL)       ALL' >> /etc/sudoers

sed -i.bak 's/run_as_user\s*=\s*.*$/run_as_user=ambari/g' '/etc/ambari-agent/conf/ambari-agent.ini'

su - ambari -c '/usr/sbin/ambari-agent start'


