# Introduction

This is a 3-tier application that is used to demonstrate the capabilities of the platform and Docker Compose. The application is based on one of the implementations of TodoBackend (http://www.todobackend.com/), Mongo and the TodoMVC client written in vanilla JavaScript (https://github.com/TodoBackend/todo-backend-client). All have been slightly modified and extended with a Docker container.

The application is composed of:

- A Mongo data store, that is used to persist all TODOs
- A stateless backend API that talks to Mongo, implemented on Node.js
- A statless client-side single-page web application that allows end users to interact with the TODOs, served by nginx
- Dynamic load balancers for the backend as well as frontend application, using the custom "alb" container

Each one of the components is runnable independently but this folder contains a Docker Compose file that deploys the application using three different containers, connected via Docker networking, onto a Swarm cluster.

# Running the application

After bootstrapping the TLDR platform, ensure your Docker client is pointing to the Swarm master:

```
eval $(docker-machine env --swarm tldr-swarm-0)
```

Next, use docker-compose to stand up the application:

```
docker-compose up -d
```

The operation will take a few minutes as Docker pulls and builds the application containers. 

When ready, run ```docker-compose ps``` to see information about the application containers. Example:

```
       Name                     Command               State                            Ports                           
---------------------------------------------------------------------------------------------------------------------
mongo               /entrypoint.sh mongod            Up      27017/tcp                                                
todo_backend_1      /start.sh                        Up      192.168.99.126:32791->8080/tcp                           
todo_backend_lb_1   consul-template -config=/t ...   Up      192.168.99.125:1936->1936/tcp, 192.168.99.125:80->80/tcp 
todo_client_1       sh -c sleep 5 && /run.sh         Up      443/tcp, 192.168.99.124:32774->80/tcp                    
todo_client_lb_1    consul-template -config=/t ...   Up      192.168.99.124:1936->1936/tcp, 192.168.99.124:80->80/tcp           
```

Only the ```todo_client_lb_1``` container is reachable externally, as it's the component that runs the load balancer and reverse proxy for the front-end part of the application. In order to access it, copy the IP address that contains port 80, ```192.168.99.124``` in this specific example (please replace the IP address accordingly)

# Scaling application components

The demo application uses an application load balancer based on Haproxy that automatically adds and removes containers from the pool as the number of components scale up and down. Only the ```client``` and ```backend``` containers can be currently scaled up or down using ```docker-compose```:

```
docker-compose scale backend=3
docker-compose scale client=3
```

When running ```docker-compose ps``` the output should be as follows:

```
      Name                     Command               State                            Ports                           
---------------------------------------------------------------------------------------------------------------------
mongo               /entrypoint.sh mongod            Up      27017/tcp                                                
todo_backend_1      /start.sh                        Up      192.168.99.126:32791->8080/tcp                           
todo_backend_2      /start.sh                        Up      192.168.99.126:32792->8080/tcp                           
todo_backend_3      /start.sh                        Up      192.168.99.126:32793->8080/tcp                           
todo_backend_lb_1   consul-template -config=/t ...   Up      192.168.99.125:1936->1936/tcp, 192.168.99.125:80->80/tcp 
todo_client_1       sh -c sleep 5 && /run.sh         Up      443/tcp, 192.168.99.124:32774->80/tcp                    
todo_client_2       sh -c sleep 5 && /run.sh         Up      443/tcp, 192.168.99.124:32775->80/tcp                    
todo_client_3       sh -c sleep 5 && /run.sh         Up      443/tcp, 192.168.99.124:32776->80/tcp                    
todo_client_lb_1    consul-template -config=/t ...   Up      192.168.99.124:1936->1936/tcp, 192.168.99.124:80->80/tcp
```

In order to verify that the scaling worked and that all the new instances are reachable via the application load balancer, use the Haproxy stats screen in port 1936 (user someuser, password) of your client or backend load balancer. Sending a few requests should update the statistics for each one of the backend nodes.

# Known issues

- Deleting or marking TODOs as completed does not currently work (adding new TODOs works just fine)