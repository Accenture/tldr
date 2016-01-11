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

- Docker Toolbox 1.9.1
- Docker Machine 0.5.2 or higher (please note that this is not currently part of the Docker Toolbox package!). The latest version from  is available at https://github.com/docker/machine/releases, but version 0.5.5 seemed to crash when dealing with the configuration of security groups upon instance creation.
- Bash/Cygwin (not fully tested in Windows)

# Usage

## Setting up locally

Checkout and install with ./start.sh. (Should write a singleliner for this)

## Setting up in AWS

Please note that Docker Machine 0.5.2 or higher is needed, or it won't work.

AWS instances are 

Set the following environment variables with your AWS secrets before running the start.sh script:

```
export AWS_ACCESS_KEY_ID=<secret key>
export AWS_SECRET_ACCESS_KEY=<secret access key>
export AWS_VPC_ID=<vpc-id>
export AWS_ZONE=<zone, one of a, b, c, d or e>
export AWS_SUBNET_ID=<subnet-id>
```

Please note that at the moment the AMI image name for the Ubuntu 15.10 image is hardcoded as ami-fe001292. This needs to be changed to be more easily configurable.

Additionally, teh following environment variables can be used to override some of the default values used for EC2 instances:

```
AWS_INSTANCE_TYPE=t2.micro
AWS_ROOT_SIZE=16
```

## Displaying important addresses

Use `./info.sh` you can display the used endpoints.

# Reference application

See README.md under apps/todo/ for more information.

# TODO

- Add more checks for partially running environment
- Add the ability to customize the AMI image for AWS
- Migrate from Logspout to Docker logging via syslog
- Create a separate network for the application containers
- Do not run with an insecure registry
- Integrate support for logging and monitoring (ELK and Prometheus are there, but not properly integrated yet)

# Known issues

- Can't mark TODOs for completion or delete them
- The Registrator container is currently an unofficial fork that implements an unmerged PR to support overlay internal IP addresses for containers, as opposed to host IP addresses. This is fine for now but we should keep an eye on upstream Registrator and switch back to it when the PR is merged.
-