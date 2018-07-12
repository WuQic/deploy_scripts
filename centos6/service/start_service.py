from AmbariService import AmbariService
import json, os, sys
import time
import urllib2

server_IP = sys.argv[1]
cluster_name = sys.argv[2]
host_file = sys.argv[3]

base_url = "http://" + server_IP + ":8080/api/v1/clusters/" + cluster_name
ambariService = AmbariService()

host_service = open(host_file)
json_array = json.loads(host_service.read())

for service in json_array:
    for key, value in service.items():
        url = "http://" + server_IP + ":8080/api/v1/clusters/" + cluster_name + "/services/" + key
        request = urllib2.Request(url)
        request.add_header('Authorization', 'Basic YWRtaW46YWRtaW4=')
        request.add_header('X-Requested-By', 'ambari')

        response_code = 0
        service_state = ""
        while not response_code == 200 or not service_state == "INSTALLED":
            try:
                response = urllib2.urlopen(request)
            except urllib2.HTTPError, err:
                print err.code
                response_code = err.code
            else:
                result = json.loads(response.read())
                service_state = result["ServiceInfo"]["state"]
                response_code = 200
                print key + " : " + service_state
            time.sleep(5)
        ambariService.start(key, base_url)
