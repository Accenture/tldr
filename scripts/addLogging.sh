#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

if [ isAWS ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  ELASTICSEARCH=http://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME):9200
  LOGSTASH=syslog://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.-aws' | awk '{print $1}' | xargs)
  KIBANA=http://$(docker-machine ip $INFRA_MACHINE_NAME):5601
  eval $(docker-machine env $INFRA_MACHINE_NAME)
else
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  ELASTICSEARCH=http://$(docker-machine ip $INFRA_MACHINE_NAME):9200
  LOGSTASH=syslog://$(docker-machine ip $INFRA_MACHINE_NAME):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.[ ]' | awk '{print $1}' | xargs)
  KIBANA=http://$(docker-machine ip $INFRA_MACHINE_NAME):5601
  eval $(docker-machine env $INFRA_MACHINE_NAME)
fi

if ! docker inspect logbox &> /dev/null; then
  print "Starting LogBox"
  docker run -d --name logbox -h logbox -p 5000:5000/udp -p 9200:9200 $REGISTRY/minilogbox
  docker run -d -p 5601:5601 -h kibanabox --name kibanabox $REGISTRY/kibanabox $ELASTICSEARCH
else
  print "LogBox already running\e[33m***\e[0m\n"
fi

print "Servers in the swarm: $SWARM_MEMBERS"
for server in $SWARM_MEMBERS; do
  if ! docker $(docker-machine config $server) inspect logspout &> /dev/null; then
    print "Starting logspout on $server"
    docker $(docker-machine config $server) run -d --name $server-logspout -h logspout -p 8100:8000 -v /var/run/docker.sock:/tmp/docker.sock $REGISTRY/logspout $LOGSTASH
  else
    print "Logspout already running on $server"
  fi
done
print "Logging system started, Kibana is available at \e[31m$KIBANA"
