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
# Provider specific names for the nodes
# TODO: prefix these with "TLDR_" to be consistent
#
REGISTRY_MACHINE_NAME="tldr-registry"
INFRA_MACHINE_NAME="tldr-infra"
SWARM_MACHINE_NAME_PREFIX="tldr-swarm"

function create_registry_node() {
  if ! docker-machine status $REGISTRY_MACHINE_NAME &> /dev/null; then
    info "Creating local private registry server"
    docker-machine create --driver virtualbox --virtualbox-memory 512 $REGISTRY_MACHINE_NAME
  if [ $? -ne 0 ]; then
    error "There was a problem creating the node."
    exit 1
  fi

  # TODO: can we move this to the common part of the process?
  REGISTRY_IP=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  docker-machine ssh $REGISTRY_MACHINE_NAME "echo $'EXTRA_ARGS=\"--insecure-registry '$REGISTRY_IP'\"' | sudo tee -a /var/lib/boot2docker/profile && sudo /etc/init.d/docker restart"
  docker $(docker-machine config $REGISTRY_MACHINE_NAME) run -d -p 5000:5000 --restart=always --name registry registry:2
  else
    REGISTRY_IP=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  fi

  eval $(docker-machine env $REGISTRY_MACHINE_NAME)
}

function create_infra_node() {
  export REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
	if ! docker-machine inspect $INFRA_MACHINE_NAME &> /dev/null; then
	  docker-machine create --driver virtualbox --engine-insecure-registry=$REGISTRY $INFRA_MACHINE_NAME
	fi

	eval $(docker-machine env $INFRA_MACHINE_NAME)
}

function create_swarm_master() {
  export NAME="$SWARM_MACHINE_NAME_PREFIX-0"
  CONSUL=$(docker-machine ip $INFRA_MACHINE_NAME)
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  ELASTICSEARCH=http://$(docker-machine ip $INFRA_MACHINE_NAME):9200
  LOGSTASH=udp://$(docker-machine ip $INFRA_MACHINE_NAME):5000

  if ! docker-machine inspect $NAME &> /dev/null; then
    info "Creating swarm master with name '$NAME' locally"
    docker-machine create --driver virtualbox \
          --swarm \
          --swarm-master  \
          --swarm-discovery consul://$CONSUL:8500 \
          --swarm-image $REGISTRY/swarm \
          --engine-opt="cluster-store=consul://$CONSUL:8500" \
          $OPTIONS \
          --engine-opt="log-driver=syslog" \
          --engine-opt="log-opt syslog-address=$LOGSTASH" \
          --engine-opt="cluster-advertise=eth1:2376" \
          --engine-insecure-registry=$REGISTRY \
          $NAME
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
        -server -bootstrap-expect 1
  else
    info "$NAME already running"
    exit 1
  fi  
}

function create_swarm_node() {
  export NAME="$SWARM_MACHINE_NAME_PREFIX-$1"
  CONSUL=$(docker-machine ip $INFRA_MACHINE_NAME)
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  ELASTICSEARCH=http://$(docker-machine ip $INFRA_MACHINE_NAME):9200
  LOGSTASH=udp://$(docker-machine ip $INFRA_MACHINE_NAME):5000

  [ $2 ] && EXTRA_OPTS="--engine-label=\"type=$2\""
  # For some reason the join only works with an IP address, not with hostname
  OVERLAY_CONSUL=$(docker $(docker-machine config $SWARM_MACHINE_NAME_PREFIX-0) inspect -f '{{(index .NetworkSettings.Networks "tldr-overlay").IPAddress}}' tldr-swarm-0-consul)
  if ! docker-machine inspect $NAME &> /dev/null; then
    info "Creating swarm node with name '$NAME' locally, label: $2"
    docker-machine create --driver virtualbox \
        --swarm \
        --swarm-discovery consul://$CONSUL:8500 \
        --swarm-image $REGISTRY/swarm \
        --engine-opt="cluster-store=consul://$CONSUL:8500" \
        --engine-opt="cluster-advertise=eth1:2376" \
        --engine-opt="log-driver=syslog" \
        --engine-opt="log-opt syslog-address=$LOGSTASH" \
        --engine-insecure-registry=$REGISTRY \
        $EXTRA_OPTS \
        $NAME

    info "Starting Consul agent"
    docker $(docker-machine config $NAME) run \
        -d \
        -p 172.17.0.1:53:53 \
        -p 172.17.0.1:53:53/udp \
        -p 8500:8500 \
        --name $NAME-consul \
        --net tldr-overlay \
        $REGISTRY/consul \
        -join $OVERLAY_CONSUL
  else
    info "$NAME already running"
    exit 1
  fi  
}

function destroy_instances() {
  INSTANCES=$(docker-machine ls --filter name="tldr" --filter driver=virtualbox -q)
  info "Destroying the following instances: $INSTANCES"
  docker-machine rm -f $INSTANCES  
}