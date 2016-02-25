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
# TODO: prefix these with "TLDR_" to be consistent
#
REGISTRY_MACHINE_NAME="tldr-registry-aws"
INFRA_MACHINE_NAME="tldr-infra-aws"
SWARM_MACHINE_NAME_PREFIX="tldr-swarm-aws"

# Name of security groups, only used by the AWS provider
TLDR_REGISTRY_SG_NAME="tldr-registry"
TLDR_NODE_SG_NAME="tldr-node"
TLDR_INFRA_NODE_SG_NAME="tldr-infra-node"	

# ID of the AMI to be used (Ubuntu 15.10 in eu-central-1); change if you know what you're doing, use 
# http://cloud-images.ubuntu.com/releases/15.10/release/ to look up the right AMI for your region
if [ -z "$TLDR_DOCKER_MACHINE_AMI" ]; then
	TLDR_DOCKER_MACHINE_AMI="ami-fe001292"
fi

# check that all AWS_ variables are in place
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
	error "Please provide your AWS access key using AWS_ACCESS_KEY_ID environment variable"
	exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
	error "Please provide your AWS secret access key using AWS_SECRET_ACCESS_KEY environment variable"
	exit 1
fi

if [ -z "$AWS_DEFAULT_REGION" ]; then
	error "Please provide your AWS region using AWS_DEFAULT_REGION environment variable"
	exit 1
fi

if [ -z "$AWS_VPC_ID" ]; then
	error "Please provide your AWS VPC id using AWS_VPC_ID environment variable"
	exit 1
fi

if [ -z "$AWS_DEFAULT_ZONE" ]; then
	error "Please provide your AWS default availability zone using AWS_DEFAULT_ZONE environment variable"
	exit 1
fi

#
# Sets up the registry node in a manner that is specific for AWS
#
function create_registry_node() {
	if ! docker-machine status $REGISTRY_MACHINE_NAME &> /dev/null; then
	  info "Creating private registry server on AWS"
	  docker-machine create --driver amazonec2 \
	  						--amazonec2-security-group $TLDR_REGISTRY_SG_NAME \
							--amazonec2-zone $AWS_DEFAULT_ZONE \
	  						$REGISTRY_MACHINE_NAME
	  if [ $? -ne 0 ]; then
	    error "There was a problem creating the node."
	    exit 1
	  fi

	  # TODO: can we move this to the common part of the process?
	  # we can't use --engine-insecure-registry  during docker-machine because at that stage we don't know the machine's own IP address yet
	  REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000	  
	  docker-machine ssh $REGISTRY_MACHINE_NAME "sudo sed -i \"/^ExecStart=/ s/\$/ --insecure-registry=$REGISTRY_IP/\" /etc/systemd/system/docker.service && sudo systemctl daemon-reload && sudo service docker restart"

	  docker $(docker-machine config $REGISTRY_MACHINE_NAME) run -d -p 5000:5000 --restart=always --name registry registry:2
	else
	  REGISTRY_IP=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
	fi
	eval $(docker-machine env $REGISTRY_MACHINE_NAME)	
}

#
# Sets up the node that contains all infrastructure components (logging, monitoring, Consul, etc)
#
function create_infra_node() {
	# Check if the node already exists
	export REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
	if ! docker-machine inspect $INFRA_MACHINE_NAME &> /dev/null; then
	  info "Creating infra node on AWS"
	  # we use larger isntance type to ensure that we have enough capacity to run Prometheus
	  docker-machine create -d amazonec2 \
	    --amazonec2-security-group $TLDR_INFRA_NODE_SG_NAME \
	    --amazonec2-instance-type t2.large \
	    --engine-insecure-registry=$REGISTRY \
	    --amazonec2-zone $AWS_DEFAULT_ZONE \
		$INFRA_MACHINE_NAME
	fi

	eval $(docker-machine env $INFRA_MACHINE_NAME)
}

function create_swarm_master() {
	NAME="$SWARM_MACHINE_NAME_PREFIX-0"
	CONSUL=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME)
  	REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  	ELASTICSEARCH=http://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME):9200
  	LOGSTASH=udp://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME):5000

	if ! docker-machine inspect $NAME &> /dev/null; then
	  info "Creating swarm master with name '$NAME' in AWS"
	  docker-machine create -d amazonec2 \
	    --swarm --swarm-master --swarm-discovery="consul://$CONSUL:8500" \
	    --swarm-image $REGISTRY/swarm \
	    --engine-opt="cluster-store=consul://$CONSUL:8500" \
	    --engine-insecure-registry="$REGISTRY" \
	    --engine-opt="cluster-advertise=eth0:2376" \
	    --engine-opt="log-driver=syslog" \
	    --engine-opt="log-opt syslog-address=$LOGSTASH" \
	    $OPTIONS \
	    --swarm-image $REGISTRY/swarm \
	    --amazonec2-ami="$TLDR_DOCKER_MACHINE_AMI" --amazonec2-security-group="$TLDR_NODE_SG_NAME" \
	    --amazonec2-zone $AWS_DEFAULT_ZONE \
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
	       -server \
	       -bootstrap-expect 1
	else
	  info "$NAME already running"
	  exit 1
	fi	
}

function create_swarm_node() {
	NAME="$SWARM_MACHINE_NAME_PREFIX-$1"
	CONSUL=$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME)
  	REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  	ELASTICSEARCH=http://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME):9200
  	LOGSTASH=udp://$(docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' $INFRA_MACHINE_NAME):5000
  	
  	[ $2 ] && EXTRA_OPTS="--engine-label=\"type=$2\""
	# For some reason the join only works with an IP address, not with hostname
	OVERLAY_CONSUL=$(docker $(docker-machine config $SWARM_MACHINE_NAME_PREFIX-0) inspect -f '{{(index .NetworkSettings.Networks "tldr-overlay").IPAddress}}' tldr-swarm-aws-0-consul)
	if ! docker-machine inspect $NAME &> /dev/null; then
	  info "Creating swarm node with name '$NAME' in AWS, label: $2"
	  docker-machine create --driver amazonec2 \
	     --swarm --swarm-discovery="consul://$CONSUL:8500" \
	     --swarm-image $REGISTRY/swarm \
	     --engine-opt="cluster-store=consul://$CONSUL:8500" \
	     --engine-opt="cluster-advertise=eth0:2376" \
	     --engine-opt="log-driver=syslog" \
	     --engine-opt="log-opt syslog-address=$LOGSTASH" \
	     $EXTRA_OPTS \
	     --engine-insecure-registry="$REGISTRY" \
	     --amazonec2-ami="$TLDR_DOCKER_MACHINE_AMI" \
	     --amazonec2-security-group="$TLDR_NODE_SG_NAME" \
	     --amazonec2-zone $AWS_DEFAULT_ZONE \
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
}