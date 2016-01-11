#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

if [ isAWS ]; then
  if ! docker-machine status $REGISTRY_MACHINE_NAME &> /dev/null; then
    print "Creating private registry server on AWS"
    docker-machine create --driver amazonec2 --amazonec2-security-group $TLDR_REGISTRY_SG_NAME $REGISTRY_MACHINE_NAME
    if [ $? -ne 0 ]; then
      error "There was a problem creating the node."
      exit 1
    fi

    REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
    # Modify the registry to be insecure
    docker-machine ssh $REGISTRY_MACHINE_NAME "echo $'DOCKER_OPTS=\"\$DOCKER_OPTS --insecure-registry='$REGISTRY_IP'\"' | sudo tee -a /etc/default/docker && sudo service docker restart"
    docker $(docker-machine config $REGISTRY_MACHINE_NAME) run -d -p 5000:5000 --restart=always --name registry registry:2
  else
    REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  fi
  eval $(docker-machine env $REGISTRY_MACHINE_NAME)
else
  if ! docker-machine status $REGISTRY_MACHINE_NAME &> /dev/null; then
    print "Creating local private registry server"
    docker-machine create --driver virtualbox --virtualbox-memory 2048 $REGISTRY_MACHINE_NAME
    if [ $? -ne 0 ]; then
      error "There was a problem creating the node."
      exit 1
    fi

    REGISTRY_IP=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
    docker-machine ssh $REGISTRY_MACHINE_NAME "echo $'EXTRA_ARGS=\"--insecure-registry '$REGISTRY_IP'\"' | sudo tee -a /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart"
    docker $(docker-machine config $REGISTRY_MACHINE_NAME) run -d -p 5000:5000 --restart=always --name registry registry:2
  else
    REGISTRY_IP=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  fi
  eval $(docker-machine env $REGISTRY_MACHINE_NAME)
fi
# Pull the images to the registry machine, tag them and push to private registry
print "Fetching images to private registry"
print "Fetching consul image"
docker pull progrium/consul
docker tag progrium/consul $REGISTRY_IP/consul
docker push $REGISTRY_IP/consul
print "Fetching swarm image"
docker pull swarm:latest
docker tag swarm:latest $REGISTRY_IP/swarm
docker push $REGISTRY_IP/swarm
print "Fetching registrator image"
docker pull kidibox/registrator
docker tag kidibox/registrator $REGISTRY_IP/registrator
docker push $REGISTRY_IP/registrator
print "Fetching minilogbox image to private registry"
docker pull sirile/minilogbox
docker tag sirile/minilogbox $REGISTRY_IP/minilogbox
docker push $REGISTRY_IP/minilogbox
print "Fetching kibanabox image to private registry"
docker pull sirile/kibanabox
docker tag sirile/kibanabox $REGISTRY_IP/kibanabox
docker push $REGISTRY_IP/kibanabox
print "Fetching logspout image to private registry"
docker pull progrium/logspout
docker tag progrium/logspout $REGISTRY_IP/logspout
docker push $REGISTRY_IP/logspout
print "Fetching prometheus image to private registry"
docker pull prom/prometheus
docker tag prom/prometheus $REGISTRY_IP/prometheus
docker push $REGISTRY_IP/prometheus
print "Fetching cadvisor image to private registry"
docker pull google/cadvisor:latest
docker tag google/cadvisor:latest $REGISTRY_IP/cadvisor
docker push $REGISTRY_IP/cadvisor
