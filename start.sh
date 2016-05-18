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

TLDR_ROOT=$(dirname ${BASH_SOURCE[0]})
TLDR_BIN=$TLDR_ROOT/bin
source $TLDR_BIN/utils.sh

function main() {
	./bin/createRegistryNode.sh
	./bin/createInfraNode.sh
	./bin/createSwarmNode.sh 0
#	./bin/createSwarmNode.sh 1 frontend
#	./bin/createSwarmNode.sh 2 application
}

# redirect all script output to a file, for troubleshooting purposes, as well as to the screen
main "$@" 2>&1 | tee log.txt

info "***"
info "Process complete. Run info.sh to get the list of accessible URLs."
info "See the instructions under apps/todo/README.md to deploy the sample application."
info "***"
