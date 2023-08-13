#!/bin/bash

export $(cat k8s-cni-bash-plugin.env)

cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf | DEBUG=1 CNI_COMMAND=DEL CNI_CONTAINERID=example CNI_NETNS=/dev/null CNI_IFNAME=dummy0 CNI_PATH=/opt/cni/bin /opt/cni/bin/k8s-cni-bash-plugin

tail /var/log/cni.log
