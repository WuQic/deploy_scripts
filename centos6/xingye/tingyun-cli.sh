#!/bin/bash -eu

EXC_USER="ambari"
result=$(echo `id |grep $EXC_USER`)
if [[ $result == '' ]]; then 
	echo "Can not execute by this user, please use user '$EXC_USER' and try again."
	exit 1
fi

ambari_server='/usr/sbin/ambari-server'

usage="Usage: tingyun [start|stop|restart|status] [all|server|agent] "

if [[ $# -ne 2 ]];then
    echo $usage
    exit 1
fi

cmd=$1
type=$2

case $type in

    (all)
    
    if [[ -f $ambari_server ]];then
        /usr/sbin/ambari-server $cmd
    fi

    /usr/sbin/ambari-agent $cmd
    
    ;;

    (server)
    if [[ ! -f $ambari_server ]];then
        echo "tingyun server is no installed in this server..."
        exit 1
    fi
    
    /usr/sbin/ambari-server $cmd

    ;;

    (agent)
        
    /usr/sbin/ambari-agent $cmd

    ;;
    
    (*)

    echo $usage
    exit 1
    ;;

esac
