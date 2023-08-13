#!/bin/bash

node_name=$(kubectl get node -o name)
kubectl debug $node_name -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0
#chroot /host
# journalctl -u kubelet 
