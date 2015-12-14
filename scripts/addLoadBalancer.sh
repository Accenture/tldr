#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

if [ $AWS_ACCESS_KEY_ID ]; then
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0-aws)
  CONSUL=$SWARM_MACHINE_NAME_PREFIX-0-aws-consul:8500
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME-aws):5000
else
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0)
  CONSUL=$SWARM_MACHINE_NAME_PREFIX-0-consul:8500
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
fi

if ! docker inspect rest &> /dev/null; then
  print "Starting HAProxy"
  docker run -d -h rest -e constraint:type==frontend --name=rest -e SERVICE_NAME=rest --dns 172.17.0.1 -p 80:80 -p 1936:1936 --net tldr-overlay $REGISTRY/haproxy -consul=$CONSUL
fi