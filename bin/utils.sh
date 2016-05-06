#!/bin/bash

# Pretty print the given string
function print() {
  printf "\e[33m==== \e[32m$1 \e[33m ====\e[0m\n"
}

function info() {
  printf "\e[32m$1\e[0m\n"
}

function warning() {
  printf "\e[33m$1\e[0m\n"
}

function error() {
  printf "\e[31mERROR: $1\e[0m\n"
}

function checkAWSData() {
  if [[ "$AWS_ACCESS_KEY_ID" == "" || "$AWS_SECRET_ACCESS_KEY" == "" || "$AWS_VPC_ID" == "" || "$AWS_DEFAULT_ZONE" == "" ]]; then
    echo "Please set environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_VPC_ID for the Amazon AWS configuration".
    exit 1
  fi
}

function checkAzureData() {
  if [[ "$AZURE_SUBSCRIPTION_ID" == "" ]]; then
    echo "Please set environment variables for Azure configuration".
    exit 1
  fi
}

function is_aws() {
  if [[ "$AWS_ACCESS_KEY_ID" == "" || "$AWS_SECRET_ACCESS_KEY" == "" || "$AWS_VPC_ID" == "" || "$AWS_DEFAULT_ZONE" == "" ]]; then
    return 1 #false 
  else
    return 0 #true
  fi
}

# Due to limitations of Docker Machine Azure driver the surface of conditions to check is smaller
function is_Azure() {
  if [[ "$AZURE_SUBSCRIPTION_ID" == "" ]]; then
    return 1 #false
  else
    return 0 #true
  fi
}

# extend this function when more providers are added
function detect_provider() {
  if is_aws; then
    echo "AWS true"
    TLDR_PROVIDER="aws"
  else 
    if is_Azure; then
      TLDR_PROVIDER="azure"
    else 
      TLDR_PROVIDER="local"
    fi
  fi
}

# return a string with the container status, as reported by docker inspect
#
function container_status() {
  docker inspect --format='{{.State.Status}}' $1  
}
