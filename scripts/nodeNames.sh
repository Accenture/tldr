#!/bin/sh

source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh

if [ isAWS ]; then
	REGISTRY_MACHINE_NAME="tldr-registry-aws"
	INFRA_MACHINE_NAME="tldr-infra-aws"
	SWARM_MACHINE_NAME_PREFIX="tldr-swarm-aws"

	# Name of security groups
	TLDR_REGISTRY_SG_NAME="tldr-registry"
	TLDR_NODE_SG_NAME="tldr-node"
else
	REGISTRY_MACHINE_NAME="tldr-registry"
	INFRA_MACHINE_NAME="tldr-infra"
	SWARM_MACHINE_NAME_PREFIX="tldr-swarm"
fi