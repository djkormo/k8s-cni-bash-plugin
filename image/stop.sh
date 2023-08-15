#!/bin/sh

echo "Destroying CNI bash plugin"
rm -f /etc/cni/net.d/10-k8s-cni-bash-plugin.conf
rm -f /opt/cni/bin/k8s-cni-bash-plugin
rm -f $CNI_LOGFILE
