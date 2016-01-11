#!/bin/bash

# Function to show colorized output for readibility
function print() {
  printf "\e[33m*** \e[31m$1 \e[33m***\e[0m\n"
}

print "Setting up registry server"
./scripts/setupRegistry.sh
print "Setting up infra"
./scripts/createInfraNode.sh
print "Creating swarm master"
./scripts/createSwarmNode.sh 0
print "Creating frontend node"
./scripts/createSwarmNode.sh 1 frontend
print "Creating application node"
./scripts/createSwarmNode.sh 2 application

echo "***"
echo "Process complete. Run the following command to point your local Docker client to the Swarm cluster:"
echo "  eval $(docker-machine env --swarm tldr-swarm-0)"
echo "***"