#!/bin/bash

docker-machine stop $(docker-machine ls --filter name=tldr -q)