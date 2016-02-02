#!/bin/bash

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh


echo registry name is $REGISTRY_MACHINE_NAME

if isAWS; then
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
print "Caching images in the private registry"

print "Caching Consul image"
docker pull progrium/consul
docker tag progrium/consul $REGISTRY_IP/consul
docker push $REGISTRY_IP/consul

print "Caching Swarm image"
docker pull swarm:latest
docker tag swarm:latest $REGISTRY_IP/swarm
docker push $REGISTRY_IP/swarm

print "Caching Registrator image"
docker pull kidibox/registrator
docker tag kidibox/registrator $REGISTRY_IP/registrator
docker push $REGISTRY_IP/registrator

print "Caching ElasticSearch image"
docker pull tldr/elasticsearch
docker tag tldr/elasticsearch $REGISTRY_IP/tldr/elasticsearch
docker push $REGISTRY_IP/tldr/elasticsearch

print "Caching Kibana image"
docker pull tldr/kibana
docker tag tldr/kibana $REGISTRY_IP/tldr/kibana
docker push $REGISTRY_IP/tldr/kibana

print "Caching Logspout image"
docker pull tldr/logspout
docker tag tldr/logspout $REGISTRY_IP/tldr/logspout
docker push $REGISTRY_IP/tldr/logspout

print "Caching Logstash image"
docker pull tldr/logstash
docker tag tldr/logstash $REGISTRY_IP/tldr/logstash
docker push $REGISTRY_IP/tldr/logstash

print "Caching Prometheus image"
docker pull tldr/prometheus
docker tag tldr/prometheus $REGISTRY_IP/tldr/prometheus
docker push $REGISTRY_IP/tldr/prometheus

print "Caching cAdvisor image"
docker pull google/cadvisor:latest
docker tag google/cadvisor:latest $REGISTRY_IP/cadvisor
docker push $REGISTRY_IP/cadvisor

print "Caching PromDash image"
docker pull tldr/promdash
docker tag tldr/promdash $REGISTRY_IP/tldr/promdash
docker push $REGISTRY_IP/tldr/promdash