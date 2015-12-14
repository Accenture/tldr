#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

# Remove logging by removing LogBox and Kibana on infra and logspout on all nodes
if [ $AWS_ACCESS_KEY_ID ]; then
  docker $(docker-machine config $INFRA_MACHINE_NAME-aws) rm -f logbox kibanabox
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0-aws)
else
  docker $(docker-machine config $INFRA_MACHINE_NAME) rm -f logbox kibanabox
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0)
fi
docker rm -f $(docker ps | awk '{print $1,$2}' | grep logspout | awk '{print $1}')
