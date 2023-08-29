#!/bin/bash

#cho '{ "cniVersion": "0.3.1", "name": "k8s-cni-bash-plugin","type": "k8s-cni-bash-plugin","network": "10.240.0.0/16", "podcidr": "10.240.0.0/24" }' | CNI_COMMAND=ADD CNI_CONTAINERID=example CNI_NETNS=/dev/null CNI_IFNAME=dummy0 CNI_PATH=. /opt/cni/bin/k8s-cni-bash-plugin
export $(cat k8s-cni-bash-plugin.env)

#cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf | CNI_COMMAND=ADD CNI_CONTAINERID=example CNI_NETNS=/dev/null CNI_IFNAME=dummy0 CNI_PATH=/opt/cni/bin /opt/cni/bin/k8s-cni-bash-plugin
rand=$(tr -dc 'A-F0-9' < /dev/urandom | head -c4)
host_if_name="veth$rand"
rand=$(tr -dc '0-9' < /dev/urandom | head -c4)
host_ns_name="$rand"
container_id="example$rand"
cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf | DEBUG=1 CNI_COMMAND=ADD CNI_CONTAINERID=$container_id CNI_NETNS=/dev/null CNI_IFNAME=$host_if_name CNI_PATH=/opt/cni/bin /opt/cni/bin/k8s-cni-bash-plugin

tail /var/log/cni.log

