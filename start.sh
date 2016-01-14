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
print "Enabing log aggregation"
./scripts/addLogging.sh

echo "***"
echo "Process complete."
echo "***"