#!/bin/bash

# Number zero is master, rest are normal swarm-nodes
[ $# -lt 1 ] || [ $1 == "-h" ] && { echo "Usage: $0 [-h] <id, 0 for master> [label]"; exit 1; }

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

[ $2 ] && OPTIONS="--engine-label=\"type=$2\""

if [ isAWS ]; then
  CONSUL=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME)
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  if [ $1 -eq 0 ]; then
    NAME="$SWARM_MACHINE_NAME_PREFIX-0"
    if ! docker-machine inspect $NAME &> /dev/null; then
      print "Creating swarm master with the name '$NAME' to AWS"
      docker-machine create -d amazonec2 \
        --swarm --swarm-master --swarm-discovery="consul://$CONSUL:8500" \
        --engine-opt="cluster-store=consul://$CONSUL:8500" --engine-insecure-registry="$REGISTRY" \
        --engine-opt="cluster-advertise=eth0:2376" $OPTIONS --swarm-image $REGISTRY/swarm \
        --amazonec2-ami="$TLDR_DOCKER_MACHINE_AMI" --amazonec2-security-group="$TLDR_NODE_SG_NAME" $NAME
      print "Creating network tldr-overlay"
      docker $(docker-machine config $NAME) network create --driver overlay tldr-overlay
      print "Starting master consul"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name tldr-swarm-$1-consul --net tldr-overlay $REGISTRY/consul -server -bootstrap-expect 1
    else
      print "$NAME already running"
      exit 1
    fi
  else
    NAME="$SWARM_MACHINE_NAME_PREFIX-$1"
    # For some reason the join only works with an IP address, not with hostname
    OVERLAY_CONSUL=$(docker $(docker-machine config $SWARM_MACHINE_NAME_PREFIX-0) inspect -f '{{(index .NetworkSettings.Networks "tldr-overlay").IPAddress}}' tldr-swarm-0-consul)
    if ! docker-machine inspect $NAME &> /dev/null; then
      print "Creating swarm node with the name '$NAME' to AWS, label: $2"
      docker-machine create --driver amazonec2 \
         --swarm --swarm-discovery="consul://$CONSUL:8500" \
         --engine-opt="cluster-store=consul://$CONSUL:8500" --engine-opt="cluster-advertise=eth0:2376" $OPTIONS --engine-insecure-registry="$REGISTRY" \
         --amazonec2-ami="$TLDR_DOCKER_MACHINE_AMI" --amazonec2-security-group="$TLDR_NODE_SG_NAME" $NAME
      print "Starting slave consul"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name tldr-swarm-$1-consul --net tldr-overlay $REGISTRY/consul -join $OVERLAY_CONSUL
    else
      print "$NAME already running"
      exit 1
    fi
  fi
  NODE_IP=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $NAME)
else
  CONSUL=$(docker-machine ip $INFRA_MACHINE_NAME)
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  if [ $1 -eq 0 ]; then
    NAME="$SWARM_MACHINE_NAME_PREFIX-0"
    if ! docker-machine inspect $NAME &> /dev/null; then
      print "Creating swarm master with the name '$NAME' locally"
      docker-machine create --driver virtualbox --swarm --swarm-master  --swarm-discovery consul://$CONSUL:8500 --swarm-image $REGISTRY/swarm --engine-opt="cluster-store=consul://$CONSUL:8500" $OPTIONS --engine-opt="cluster-advertise=eth1:2376" --engine-insecure-registry=$REGISTRY $NAME
      print "Creating network tldr-overlay"
      docker $(docker-machine config $NAME) network create --driver overlay tldr-overlay
      print "Starting master consul"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name tldr-swarm-$1-consul --net tldr-overlay $REGISTRY/consul -server -bootstrap-expect 1
    else
      print "$NAME already running"
      exit 1
    fi
  else
    NAME="$SWARM_MACHINE_NAME_PREFIX-$1"
    # For some reason the join only works with an IP address, not with hostname
    OVERLAY_CONSUL=$(docker $(docker-machine config $SWARM_MACHINE_NAME_PREFIX-0) inspect -f '{{(index .NetworkSettings.Networks "tldr-overlay").IPAddress}}' tldr-swarm-0-consul)
    if ! docker-machine inspect $NAME &> /dev/null; then
      print "Creating swarm node with the name '$NAME' locally, label: $2"
      docker-machine create --driver virtualbox --swarm --swarm-discovery consul://$CONSUL:8500 --engine-opt="cluster-store=consul://$CONSUL:8500" --engine-opt="cluster-advertise=eth1:2376" $OPTIONS --engine-insecure-registry=$REGISTRY $NAME
      print "Starting slave consul"
      docker $(docker-machine config $NAME) run -d -p 172.17.0.1:53:53 -p 172.17.0.1:53:53/udp -p 8500:8500 --name tldr-swarm-$1-consul --net tldr-overlay $REGISTRY/consul -join $OVERLAY_CONSUL
    else
      print "$NAME already running"
      exit 1
    fi
  fi
  NODE_IP=$(docker-machine ip $NAME)
fi
eval $(docker-machine env $NAME)
print "Starting registrator"
docker run -d -v /var/run/docker.sock:/tmp/docker.sock -h registrator --name tldr-swarm-$1-registrator --net tldr-overlay $REGISTRY/registrator -internal consul://tldr-swarm-$1-consul:8500
print "Started a new node with IP \e[31m$(docker-machine ip $NAME)"
