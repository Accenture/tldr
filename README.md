# The Lightweight Docker Runtime (TLDR)

# General

This is the first draft of a custom Docker based runtime to support 3-tier stateless applications.

# Features

- Docker Machine to provision a cluster, either locally via VirtualBox or on Amazon AWS
- 3-node Docker Swarm cluster
- Dynamic service discovery and registration using Consul and Registrator
- Deployment of applications via Docker Compose
- Transparent application container load balancing using the tldr_alb container, which provides seamless scaling of application containers within the Swarm cluster
- Log aggregation via Logspout, ElasticSearch, Kibana and Logstash 
- Monitoring and metrics via Prometheus and cAdvisor

# Pre-requisites

The following are needed to get this environment running:

- Docker Toolbox 1.9
- Bash/Cygwin (not fully tested in Windows)

# Usage

## Setting up locally

Use script ```start.sh``` to set up the Docker Swarm platform and technical components. The process should take approximately 10 minutes, depending on the specs of your host machine as well as the speed of your network connection (several containers will be pulled from the Docker Hub, and cached locally).

Once the process is complete, run ```info.sh``` to provide a list of the available endpoints for inspection.

See apps/todo/README.md for deploying the To-Do demo application.

## Setting up in AWS

Support for setting the platform up on AWS is currently in progress.

# Reference application

See README.md under apps/todo/ for more information.

# TODO

- Add more checks for partially running environment
- Add the ability to customize the AMI image for AWS
- Migrate from Logspout to Docker logging via syslog
- Create a separate network for the application containers
- Better demo applications

# Known issues

- The todo application cannot currently be deployed to Amazon AWS
- The application load balancer container will sometimes fail to reload the list of nodes 
- Can't mark TODOs for completion or delete them
- The Registrator container is currently an unofficial fork that implements an unmerged PR to support overlay internal IP addresses for containers, as opposed to host IP addresses. This is fine for now but we should keep an eye on upstream Registrator and switch back to it when the PR is merged.