#!/bin/bash

# This script sets up a node for development purposes; should not be needed to run the platform

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

DEV_NODE_NAME="tldr-dev"

# Creates infra node if needed
if [ isAWS ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  # Check if the node already exists
  if ! docker-machine inspect tldr-dev &> /dev/null; then
    print "Creating development node in AWS"
    docker-machine create -d amazonec2 --engine-insecure-registry=$REGISTRY $DEV_NODE_NAME-aws
  fi
  eval $(docker-machine env $INFRA_MACHINE_NAME)
else
  if [ isAzure ]; then
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  else
    REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
    if ! docker-machine inspect $DEV_NODE_NAME &> /dev/null; then
      print "Creating development node locally"
      docker-machine create -d virtualbox --engine-insecure-registry=$REGISTRY $DEV_NODE_NAME
    fi
    eval $(docker-machine env $DEV_NODE_NAME)
  fi
fi
