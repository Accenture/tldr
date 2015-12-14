#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

# Remove monitoring by removing Prometheus from infra node and cAdvisor from everywhere
if [ $AWS_ACCESS_KEY_ID ]; then
  docker $(docker-machine config $INFRA_MACHINE_NAME-aws) rm -f prometheus
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0-aws)

else
  docker $(docker-machine config $INFRA_MACHINE_NAME) rm -f prometheus
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0)
fi
docker rm -f $(docker ps | awk '{print $1,$2}' | grep cadvisor | awk '{print $1}')
