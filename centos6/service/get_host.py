import json
import os
import sys

host_file = open(sys.argv[1])
host_output = sys.argv[2]

json_array = json.loads(host_file.read())

for service in json_array:
    for key, value in service.items():
        for component_key, component_value in value.items():
           if component_key == "SUGO_ANALYSE_UI":
                m = open(host_output, 'a+')
                m.write("astro_host " + component_value[0] + "\n")
                m.close()
           elif component_key == "SUGO_NAMENODE":
                m = open(host_output, 'a+')
                m.write("namenode1 " + component_value[0] + "\n")
                m.write("namenode2 " + component_value[1] + "\n")
                m.close()
           elif component_key == "SUGO_POSTGRES_SERVER":
                m = open(host_output, 'a+')
                m.write("postgres_host " + component_value[0] + "\n")
                m.close()
           elif component_key == "SUGO_REDIS_SERVER":
                m = open(host_output, 'a+')
                m.write("redis_host " + component_value[0] + "\n")
                m.close()
           elif component_key == "SUGO_GATEWAY_SERVER":
                m = open(host_output, 'a+')
                m.write("gateway_host " + component_value[0] + "\n")
                m.close()
           elif component_key == "HIVE_JDBC_SERVER":
                m=open(host_output, 'a+')
                m.write("hive_jdbc_host " + component_value[0] + "\n")
                m.close()
            elif component_key == "SUGO_UINDEX_HMASTER":
                m=open(host_output, 'a+')
                m.write("hmaster_host " + component_value[0] + "\n")
                m.close()
