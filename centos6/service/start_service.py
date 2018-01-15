from AmbariService import AmbariService
import json, os, sys
import time

server_IP = sys.argv[1]
cluster_name = sys.argv[2]
host_file = sys.argv[3]

base_url = "http://" + server_IP + ":8080/api/v1/clusters/" + cluster_name
ambariService = AmbariService()

host_service = open(host_file)
json_array = json.loads(host_service.read())

for service in json_array:
    for key, value in service.items():
        os.system("date >> /root/stateofdatanode.log; netstat -nap | grep 50020 >> /root/stateofdatanode.log")
        ambariService.start(key, base_url)
        print "starting: " + key
	os.system("date >> /root/stateofdatanode.log; netstat -nap | grep 50020 >> /root/stateofdatanode.log")
        time.sleep(10)
