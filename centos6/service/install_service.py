from AmbariService import AmbariService
import json, sys
import time

cluster_name = sys.argv[2]
server_IP = sys.argv[1]
host_file = sys.argv[3]

base_url = "http://" + server_IP + ":8080/api/v1/clusters/" + cluster_name
ambariService = AmbariService()

host_service = open(host_file)
json_array = json.loads(host_service.read())

for service in json_array:
    for key, value in service.items():
        ambariService.addservice(key, base_url)

        ambariService.addcomponent(value, base_url)

        ambariService.create_apply_config(key, base_url)


        ambariService.create_host_component(value, base_url)

        ambariService.installservice(key, base_url)
        print "installing: " + key
        time.sleep(3)
        #ambariService.start(key, base_url)
