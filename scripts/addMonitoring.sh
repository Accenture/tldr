#!/bin/bash
source $(dirname ${BASH_SOURCE[0]})/docker-functions.sh
source $(dirname ${BASH_SOURCE[0]})/nodeNames.sh

if [ isAWS ]; then
  REGISTRY=$(docker-machine inspect --format='{{.Driver.PrivateIPAddress}}' $REGISTRY_MACHINE_NAME):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-aws-.' | awk '{print $1}' | xargs)
  SERVERS="['$(docker-machine ls | grep 'swarm-aws-.' | awk '{print $1}' | xargs -I{} docker-machine inspect --format '{{.Driver.PrivateIPAddress}}' {} | xargs | sed -e "s/ /:8080','/g"):8080']"
  PROMETHEUS=http://$(docker-machine ip $INFRA_MACHINE_NAME):9090
  PROMDASH=http://$(docker-machine ip $INFRA_MACHINE_NAME):3000
  eval $(docker-machine env $INFRA_MACHINE_NAME)
else
  REGISTRY=$(docker-machine ip $REGISTRY_MACHINE_NAME):5000
  SWARM_MEMBERS=$(docker-machine ls | grep 'swarm-.[ ]' | awk '{print $1}' | xargs)
  SERVERS="['$(docker-machine ip $(docker-machine ls | grep 'swarm-.[ ]' | awk '{print $1}' ) | xargs | sed -e "s/ /:8080','/g"):8080']"
  PROMETHEUS=http://$(docker-machine ip $INFRA_MACHINE_NAME):9090
  PROMDASH=http://$(docker-machine ip $INFRA_MACHINE_NAME):3000
  eval $(docker-machine env $INFRA_MACHINE_NAME)
fi

print "Servers in the swarm: $SWARM_MEMBERS"
for server in $SWARM_MEMBERS; do
  if ! docker $(docker-machine config $server) inspect cadvisor &> /dev/null; then
    print "Starting cadvisor on $server"
    docker $(docker-machine config $server) run \
        --name cadvisor \
        --volume=/:/rootfs:ro \
        --volume=/var/run:/var/run:rw \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:ro \
        --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
        --publish=8080:8080 \
        --detach=true \
        --name=cadvisor \
        --restart=always \
        $REGISTRY/cadvisor
  else
    print "cadvisor already running on $server"
  fi
done

if ! docker inspect prometheus &> /dev/null; then
  print "Starting Prometheus"
  # With alert manager it would be like:
  # docker run -d -p 9093:9093 -v $PWD/alertmanager.conf:/alertmanager.conf prom/alertmanager -config.file=/alertmanager.conf
  # docker $(docker-machine config infra) run -d -p 9090:9090 --name prometheus -v $PWD/prometheus.yml:/etc/prometheus/prometheus.yml -v $PWD/alert.rules:/etc/prometheus/alert.rules prom/prometheus -config.file=/etc/prometheus/prometheus.yml -alertmanager.url=http://$(docker-machine ip infra):9093
  
  docker run -d --name prometheus -h prometheus --dns 172.17.0.1 -p 9090:9090 $REGISTRY/tldr/prometheus
else
  print "Prometheus is already running"
fi

if ! docker inspect promdash &> /dev/null; then
  print "Starting PromDash"
    docker run -d --name promdash -h promdash --dns 172.17.0.1 -p 3000:3000 $REGISTRY/tldr/promdash
else
  print "PromDash is already running"
fi

print "Prometheus UI can be found at \e[31m$PROMETHEUS"
print "PromDash UI can be found at \e[31m$PROMDASH"