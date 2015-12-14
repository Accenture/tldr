#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

if [ $AWS_ACCESS_KEY_ID ]; then
  REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME-aws):5000
  eval $(docker-machine env $REGISTRY_MACHINE_NAME-aws)
else
  REGISTRY_IP=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  eval $(docker-machine env $REGISTRY_MACHINE_NAME)
fi
print "Pulling image $1 to private registry"
NAME=$REGISTRY_IP/$(basename $1)
docker pull $1
docker tag $1 $NAME
docker push $NAME
print "Tagged the image with name $NAME and pushed"
