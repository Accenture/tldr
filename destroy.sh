#!/bin/bash

#TODO Add timer to allow user intervention if destroying in error
docker-machine rm $(docker-machine ls --filter name=tldr -q)