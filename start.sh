#!/bin/bash

# Function to show colorized output for readibility
function print() {
  printf "\e[33m*** \e[31m$1 \e[33m***\e[0m\n"
}

print "Setting up registry server"
./bin/createRegistryNode.sh
print "Setting up infra"
./bin/createInfraNode.sh
print "Creating swarm master"
./bin/createSwarmNode.sh 0
print "Creating frontend node"
./bin/createSwarmNode.sh 1 frontend
print "Creating application node"
./bin/createSwarmNode.sh 2 application

info "***"
info "Process complete."
info "***"