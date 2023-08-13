#!/bin/bash

git pull
make
make publish-version
make publish-latest
docker images | grep k8s-cni-bash
