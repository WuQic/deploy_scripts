import json, sys, os

output_file=sys.argv[1]
lines=open(output_file, "r+").readlines()
if os.path.exists("hosts_csv.json"):
    os.remove("hosts_csv.json")
services1=[]
service1={}
#a=["POSTGRES_SUGO", "REDIS_SUGO", "ZOOKEEPER_SUGO", "GATEWAY_SUGO", "DRUIDIO_SUGO", "ASTRO_SUGO"]
a=str(sys.argv[2:])
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

for srv in a:
    obj={srv: service1[srv]}
    services1.append(obj)

m=open("hosts_csv.json", 'w')
m.write(str(json.dumps(services1)))
m.close()