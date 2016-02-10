#!/bin/bash

# Copyright 2016 The Lightweight Docker Runtime contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Sets up the registry node; first is delegates the actual provisioning of the node to the provider-
# specific scripts, and then pulls containers to be cached in a common manner

TLDR_ROOT=$(dirname ${BASH_SOURCE[0]})/..
TLDR_BIN=$TLDR_ROOT/bin
source $TLDR_BIN/utils.sh

# Creates infra node if needed
detect_provider
info "Using provider: ${TLDR_PROVIDER}"
source $TLDR_BIN/providers/$TLDR_PROVIDER/provider.sh

create_registry_node

info "Caching images in the private registry"

info "Caching Consul image"
docker pull progrium/consul
docker tag progrium/consul $REGISTRY_IP/consul
docker push $REGISTRY_IP/consul

info "Caching Swarm image"
docker pull swarm:latest
docker tag swarm:latest $REGISTRY_IP/swarm
docker push $REGISTRY_IP/swarm

info "Caching Registrator image"
docker pull kidibox/registrator
docker tag kidibox/registrator $REGISTRY_IP/registrator
docker push $REGISTRY_IP/registrator

info "Caching ElasticSearch image"
docker pull tldr/elasticsearch
docker tag tldr/elasticsearch $REGISTRY_IP/tldr/elasticsearch
docker push $REGISTRY_IP/tldr/elasticsearch

info "Caching Kibana image"
docker pull tldr/kibana
docker tag tldr/kibana $REGISTRY_IP/tldr/kibana
docker push $REGISTRY_IP/tldr/kibana

info "Caching Logspout image"
docker pull tldr/logspout
docker tag tldr/logspout $REGISTRY_IP/tldr/logspout
docker push $REGISTRY_IP/tldr/logspout

info "Caching Logstash image"
docker pull tldr/logstash
docker tag tldr/logstash $REGISTRY_IP/tldr/logstash
docker push $REGISTRY_IP/tldr/logstash

info "Caching cAdvisor image"
docker pull google/cadvisor:latest
docker tag google/cadvisor:latest $REGISTRY_IP/cadvisor
docker push $REGISTRY_IP/cadvisor

info "Caching Prometheus image"
docker pull tldr/prometheus
docker tag tldr/prometheus $REGISTRY_IP/tldr/prometheus
docker push $REGISTRY_IP/tldr/prometheus

info "Caching PromDash image"
docker pull tldr/promdash
docker tag tldr/promdash $REGISTRY_IP/tldr/promdash
docker push $REGISTRY_IP/tldr/promdash