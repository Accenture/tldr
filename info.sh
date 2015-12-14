#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/scripts/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/scripts/nodeNames.sh
if [ $AWS_ACCESS_KEY_ID ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME-aws):5000
  PROMETHEUS=http://$(docker-machine ip $INFRA_MACHINE_NAME-aws):9090
  KIBANA=http://$(docker-machine ip $INFRA_MACHINE_NAME-aws):5601
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0-aws)
else
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  PROMETHEUS=http://$(docker-machine ip $INFRA_MACHINE_NAME):9090
  KIBANA=http://$(docker-machine ip $INFRA_MACHINE_NAME):5601
  eval $(docker-machine env --swarm $SWARM_MACHINE_NAME_PREFIX-0)
fi
print "Kibana is available at \e[31m$KIBANA"
print "Prometheus is available at \e[31m$PROMETHEUS"
print "Registry is available at \e[31m$REGISTRY"
