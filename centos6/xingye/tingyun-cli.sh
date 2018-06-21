#!/bin/bash -eu

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
