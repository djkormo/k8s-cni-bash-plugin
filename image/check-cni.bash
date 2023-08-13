#!/bin/bash

#cho '{ "cniVersion": "0.3.1", "name": "k8s-cni-bash-plugin","type": "k8s-cni-bash-plugin","network": "10.240.0.0/16", "podcidr": "10.240.0.0/24" }' | CNI_COMMAND=ADD CNI_CONTAINERID=example CNI_NETNS=/dev/null CNI_IFNAME=dummy0 CNI_PATH=. /opt/cni/bin/k8s-cni-bash-plugin
export $(cat k8s-cni-bash-plugin.env)

cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf | CNI_COMMAND=ADD CNI_CONTAINERID=example CNI_NETNS=/dev/null CNI_IFNAME=dummy0 CNI_PATH=/opt/cni/bin /opt/cni/bin/k8s-cni-bash-plugin

cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf | DEBUG=1 CNI_COMMAND=ADD CNI_CONTAINERID=example CNI_NETNS=/dev/null CNI_IFNAME=dummy0 CNI_PATH=/opt/cni/bin /opt/cni/bin/k8s-cni-bash-plugin

tail /var/log/cni.log

