import json, sys, os

output_file=sys.argv[1]
lines=open(output_file, "r+").readlines()
if os.path.exists("hostbeforhdfs.json"):
    os.remove("hostbeforhdfs.json")
if os.path.exists("hostafterhdfs.json"):
    os.remove("hostafterhdfs.json")
services1=[]
services2=[]
service1={}
service2={}
a=["POSTGRES_SUGO", "REDIS_SUGO", "ZOOKEEPER_SUGO", "HDFS_SUGO"]
#b=["YARN_SUGO", "MAPREDUCE_SUGO", "KAFKA_SUGO", "GATEWAY_SUGO", "DRUIDIO_SUGO", "ASTRO_SUGO"]
b=str(sys.argv[2:])
for line in lines:
    components={}
    server=line.split(",")[0]
    component=line.split(",")[1]
    hosts=[]
    for y in range(2,len(line.strip().strip(',').split(","))):
        if line.strip().split(",")[y] != "":
            hosts.append(line.strip().split(",")[y])
    components[component]=hosts
    if service1.keys():
        if server in service1.keys():
            service1[server][component]=hosts
        else:
            service1[server]=components
    else:
        service1[server]=components
    if service2.keys():
        if server in service2.keys():
            service2[server][component]=hosts
        else:
            service2[server]=components
    else:
        service2[server]=components

for srv in a:
    obj={srv: service1[srv]}
    services1.append(obj)

for srv in b:
    obj={srv: service2[srv]}
    services2.append(obj)

m=open("hostbeforhdfs.json", 'w')
m.write(str(json.dumps(services1)))
m.close()
n=open("hostafterhdfs.json", 'w')
n.write(str(json.dumps(services2)))
n.close()
