#!/bin/bash

# Copyright 2016 The Lightweight Docker Runtime contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


TLDR_ROOT=$(dirname ${BASH_SOURCE[0]})/../../..
TLDR_BIN=$TLDR_ROOT/bin

#
# provider specific names for the nodes
#
REGISTRY_MACHINE_NAME="tldr-registry-azure"
INFRA_MACHINE_NAME="tldr-infra-azure"
SWARM_MACHINE_NAME_PREFIX="tldr-swarm-azure"

# check that all azure_ variables are in place
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
	error "Please provide your Azure Subscription by using AZURE_SUBSCRIPTION_ID environment variable"
	exit 1
fi

#
# Sets up the registry node in a manner that is specific for Azure
#
function create_registry_node() {
  #Registry Node is created by Terraform, so only action is to modify the existing node
  #In the future, when Docker Machine Azure driver supports private subnets then logic will be added here
  REGISTRY_IP=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000

  docker $(docker-machine config $REGISTRY_MACHINE_NAME) run -d -p 5000:5000 --restart=always --name registry registry:2
	
  eval $(docker-machine env $REGISTRY_MACHINE_NAME)
}

#
# Sets up the node that contains all infrastructure components (logging, monitoring, Consul, etc)
#
function create_infra_node() {
  #For Azure the Infra Node is created by Terraform, so only action is to point to it
  #In the future, when Docker Machine Azure driver supports private subnets then logic will be added here

  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
	#TEMP
	echo "registry is $REGISTRY"
  eval $(docker-machine env $INFRA_MACHINE_NAME)

}

function create_swarm_master() {
  #Assigning values, we can use docker-machine ip
  NAME="$SWARM_MACHINE_NAME_PREFIX-0"
  CONSUL=$(docker-machine ip $INFRA_MACHINE_NAME)
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000 
  ELASTICSEARCH=http://$(docker-machine ip $INFRA_MACHINE_NAME):9200
  LOGSTASH=udp://$(docker-machine ip $INFRA_MACHINE_NAME):5000

  #Swarm Node is created by Terraform, so only action is to modify the existing node
  #In the future, when Docker Machine Azure driver supports private subnets then logic will be added here
 
   info "Configuring swarm master with name '$NAME' in Azure"
   info "Creating network tldr-overlay"
   docker $(docker-machine config $NAME) network create --driver overlay tldr-overlay
	  
   info "Starting master consul"
   docker $(docker-machine config $NAME) run \
        -d \
        -p 172.17.0.1:53:53 \
        -p 172.17.0.1:53:53/udp \
        -p 8500:8500 \
        --name $NAME-consul \
        --net tldr-overlay \
        $REGISTRY/consul \
        -server \
        -bootstrap-expect 1
}


function create_swarm_node() {
  NAME="$SWARM_MACHINE_NAME_PREFIX-$1"
  CONSUL=$(docker-machine ip $INFRA_MACHINE_NAME)
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000	
  ELASTICSEARCH=http://$(docker-machine ip $INFRA_MACHINE_NAME):9200
  LOGSTASH=udp://$(docker-machine ip $INFRA_MACHINE_NAME):5000
  
  [ $2 ] && EXTRA_OPTS="--engine-label=\"type=$2\""
  #For some reason the join only works with an IP address, not with hostname
#  OVERLAY_CONSUL=$(docker $(docker-machine config $SWARM_MACHINE_NAME_PREFIX-0) inspect -f '{{(index .NetworkSettings.Networks "tldr-overlay").IPAddress}}' tldr-swarm-aws-0-consul)
  
  if ! docker-machine inspect $NAME &> /dev/null; then
    NODEIP=(dcoker-machine ip $NAME)
    RM=$(docker-machine rm $NAME)
    if ! docker-machine inspect $NAME &> /dev/null; then         
      info "Recreating swarm node with name '$NAME' in Azure, label: $2"
      docker-machine create --driver generic \
             --generic-ip-address=$IPSWARM \
             --generic-ssh-user=azureuser \
	     --swarm --swarm-discovery="consul://$CONSUL:8500" \
	     --swarm-image $REGISTRY/swarm \
	     --engine-opt="cluster-store=consul://$CONSUL:8500" \
	     --engine-opt="cluster-advertise=eth0:2376" \
	     --engine-opt="log-driver=syslog" \
	     --engine-opt="log-opt syslog-address=$LOGSTASH" \
	     $EXTRA_OPTS \
	     $NAME
      info "Starting Consul agent"
      docker $(docker-machine config $NAME) run -d \
         -p 172.17.0.1:53:53 \
         -p 172.17.0.1:53:53/udp \
         -p 8500:8500 \
         --name $NAME-consul \
         --net tldr-overlay \
         $REGISTRY/consul -join $OVERLAY_CONSUL
    else
      info "$NAME already running"
      exit 1
    fi
  fi
}


function destroy_instances() {
  #As Azure is provisioned through Terrarform
  ( cd $TLDR_BIN/../providers/azure && terraform destroy )

}

