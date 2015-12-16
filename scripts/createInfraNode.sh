#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

# Creates infra node if needed
if [ isAWS ]; then
  # Check if the node already exists
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  if ! docker-machine inspect $INFRA_MACHINE_NAME &> /dev/null; then
    print "Creating infra node into AWS"
    docker-machine create -d amazonec2 --engine-insecure-registry=$REGISTRY $INFRA_MACHINE_NAME
  fi
  eval $(docker-machine env $INFRA_MACHINE_NAME)
else
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  if ! docker-machine inspect $INFRA_MACHINE_NAME &> /dev/null; then
    print "Creating infra node locally"
    docker-machine create -d virtualbox --engine-insecure-registry=$REGISTRY $INFRA_MACHINE_NAME
  fi
  eval $(docker-machine env $INFRA_MACHINE_NAME)
fi
# Start Consul if not already running
if ! docker inspect consul &> /dev/null; then
  print "Starting consul container"
  docker run -d -p 8500:8500 --name consul $REGISTRY/consul -server -bootstrap-expect 1
else
  print "Consul already running"
fi
