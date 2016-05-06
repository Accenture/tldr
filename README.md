# The Lightweight Docker Runtime (TLDR) 
How to deploy in Azure Cloud Provider

# General

The purpose of The Lightweight Docker Runtime is to serve as a platform that is easy to stand up on a variety of providers, to be able  easily demonstrate the key concepts and capabilities that we believe should be part of a container platform such as composition of applications via Docker Compose, clustering via Swarm, and service discovery, among others.

TLDR is not production-ready or enterprise-grade, nor does it intend to be.

# Features

- Docker Machine to provision a cluster, either locally via VirtualBox or on Amazon AWS
- 3-node Docker Swarm cluster (easily expandable to more nodes)
- Dynamic service discovery and registration using Consul and Registrator
- Deployment of applications via Docker Compose and overlay networks
- Transparent application container load balancing using the tldr/alb container, which provides seamless scaling of application containers within the Swarm cluster
- Log aggregation via Logspout, ElasticSearch, Kibana and Logstash 
- Monitoring and metrics via Prometheus and cAdvisor

# Pre-requisites

The following are needed to get this environment running:

- Docker Toolbox 1.9.1
- Docker Machine 0.6.0 or higher
- Bash/Cygwin if running on Windows

When running locally, 8Gb of RAM is the minimum recommended amount of memory in order to comfortably run all components.

# Usage

## Setting up locally

Use script ```start.sh``` to set up the Docker Swarm platform and technical components. The process should take approximately 10-15 minutes, depending on the specs of your host machine as well as the speed of your network connection (several containers will be pulled from the Docker Hub, and cached locally).

Once the process is complete, run ```info.sh``` to provide a list of the available endpoints for inspection.

## Setting up in Azure
Requirements: docker-machine, docker-compose, Terraform, Git, TLDR project

Summarized steps: 
	1 Prepare your Linux box by installing docker-machine, docker-compose, Terraform and Git application. 
	2 Configure your Azure parameters.
	3 Git clone the tldr project.
	4 Run the terraform.tf script to deploy infrastructure: 5 VMs
	5 Check your Swarm cluster is working fine and all hosts are accessible via docker-machine
	6  Run start.sh script
	7 Make the Swarm master node the active one
	8 Deploy application via docker-compose

Requirements
1 Linux instance
Use your own one, no matter if it is a bare metal, VirtualBox, Amazon hosted, etc. In our example we will use an Amazon Linux VM.

2 Azure Account
Please note this first release it is only available for Azure Service Management, most likely we´ll release one for Azure Resource Manager soon.

3 Docker engine, quick installation guide:
   Update packages first:
   [ec2-user ~]$ sudo yum update -y
   Install docker
   [ec2-user ~]$ sudo yum install -y docker
   Start the docker service 
   [ec2-user ~]$ sudo service docker start
     Starting cgconfig service:                        [  OK  ]
     Starting docker:	                                 [  OK  ]
   Add your user to the docker group:
   [ec2-user ~]$ sudo usermod -a -G docker ec2-user
4 Docker-machine, quick installation:
   Download the right binary, for a 64 bits Linux this is the right one: 
   [ec2-user ~]$ curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine && \
   chmod +x /usr/local/bin/docker-machine
   In case of errors perform the operation in your user directory and then copy docker-machine binary to /usr/local/bin
5 Docker-compose
  [ec2-user ~]$ curl -L https://github.com/docker/compose/releases/download/1.7.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
Note
In case of permission issues copy the binary to your local folder and then move it to /usr/local/bin, please verify your user .bashrc file to double check that location is already added to your PATH envirnonment variable

6 Azure
  •	It is requiered to add your Linux an environment variable
  $AZURE_SUBSCRIPTION_ID
  •	Please get your Azure Publish Settings file, something you can do by running the following Azure powershell command:
		Get-AzurePublishSettingsFile
	More information https://msdn.microsoft.com/en-us/library/dn385850(v=nav.70).aspx
7 Private/Public SSH key
You will need to use public/private keys with docker-machine combined with the generic driver, when discovering nodes generic driver relies on user and SSH keys, let quickly remind how to perform this operation. Once in your Linux box please run the following commands:
[ec2-user ~]ssh-keygen -t rsa
Accept default options, your public key will be saved in your user .ssh/id_rsa.pub file, while the private part will be found in /home/”youruser”/.ssh/id_rsa.pub
8 Terraform
Copy the Terraform binary and unzip it, you might do it in /usr/bin which usually is in your Linux path (environment variable).
[ec2-user ~]$ wget https://releases.hashicorp.com/terraform/0.6.15/terraform_0.6.15_linux_amd64.zip
[ec2-user ~]$ unzip terraform_0.6.15_linux_amd64.zip
Terraform requires de credentials.publishingsettings file to connect properly to the Azure account where you want to deploy your TLDR infrastructure.
9 Git
Run the following command to install git tool. Please realize this example shows the action through yum tool, if you are working on a Debian based as Ubuntu please use apt-get instead.
[ec2-user ~]$ sudo yum –y install git
10 TLDR
Get the TLDR repository and perform the clone into your local folder:
[ec2-user ~]$ git clone https://github.com/Accenture/tldr.git

Deploying infrastructure in Azure
Let´s start deploying infrastructure, go to the tldr folder and look for the Azure one inside provisioning, you should find a terraform.tf script.
[ec2-user ~]$ cd tldr/provisioning/azure/

Some required changes (aka “tunning”)
Terraform script is configured with a specific key combination for a specific user, in this example ec2-user, change this values in each “provisioner “local exec” section by changing ec2-user for yours.
Copy your public/private key combination you generated before to this folder, it should be located at /home/youruser/.ssh/
  provisioner file {
        source = "/home/ec2-user/.ssh/id_rsa.pub"
        destination = "/home/azureuser/.ssh/authorized_keys"
   }     
To run the script just type:
[ec2-user ~]$ terraform plan
which will show you what the script is going to do, in order to execute, please type:
[ec2-user ~]$ terraform apply
Now double check by running docker-machine ls to verify swarm cluster is perfectly built up. See below screenshot.
Configuring the Registry, deploying monitoring tools
1 Go to tldr folder and run start.sh script, do not forget to set the Azure_ID environment variable or that script won´t be able to discern the cloud provider destination.
[ec2-user ~]$ ./start.sh
Now point to the node-0, meaning making that node the active one where deploy the application
[ec2-user@ip-172-31-13-65 todo]$ eval $(docker-machine env --swarm tldr-swarm-azure-0)
Verify node 0 is the active one by running docker-machine ls, or just type docker info to check you are located on the master
Now change directory to the /tldr/apps/todo folder where the compose YML file is located at:
Please run the application:
[ec2-user@ip-172-31-13-65 todo]$ docker-compose up –d

Use [TLDR's Github issue page](https://github.com/Accenture/tldr/issues) to report issues related to TLDR or any of its components. Do not report issues in subprojects as that would become a nightmare to main and we'd rather keep issues and contributions centralized.

When reporting an issue, please paste the contents of your *log.txt* file into the issue for our reference (this file is created automatically by start.sh). If you used the individual scripts that are under bin/ instead, please paste the output of your screen.

# Contributing

TLDR is licensed under the Apache 2.0 license. Pull requests with contributions are more than welcome.

# Releases

[Release 1.0](https://github.com/accenture/tldr/issues?q=is%3Aissue+milestone%3A1.0+is%3Aclosed)

# TODO, Known issues

Please see the [list of open issues](https://github.com/Accenture/tldr/issues) for more details.
