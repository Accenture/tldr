#!/bin/sh

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh

if isAWS; then
	REGISTRY_MACHINE_NAME="tldr-registry-aws"
	INFRA_MACHINE_NAME="tldr-infra-aws"
	SWARM_MACHINE_NAME_PREFIX="tldr-swarm-aws"

	# Name of security groups
	TLDR_REGISTRY_SG_NAME="tldr-registry"
	TLDR_NODE_SG_NAME="tldr-node"
	TLDR_INFRA_NODE_SG_NAME="tldr-infra-node"	

	# ID of the AMI to be used (Ubuntu 15.10 in eu-central-1); change if you know what you're doing, use 
	# http://cloud-images.ubuntu.com/releases/15.10/release/ to look up the right AMI for your region
	if [ -z "$TLDR_DOCKER_MACHINE_AMI" ]; then
		TLDR_DOCKER_MACHINE_AMI="ami-fe001292"
	fi
else
	REGISTRY_MACHINE_NAME="tldr-registry"
	INFRA_MACHINE_NAME="tldr-infra"
	SWARM_MACHINE_NAME_PREFIX="tldr-swarm"
fi
