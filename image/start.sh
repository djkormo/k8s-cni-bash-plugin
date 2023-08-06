#!/bin/sh

echo "Initialising CNI bash plugin"

echo "======== Configuration ========="
cat 10-k8s-cni-bash-plugin.conf
echo "======== Configuration ========="

cp 10-k8s-cni-bash-plugin.conf /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

echo "====== Installed cni plugings ==========="
cp k8s-cni-bash-plugin.bash /opt/cni/bin/k8s-cni-bash-plugin
chmod +x /opt/cni/bin/k8s-cni-bash-plugin

ls -la  /opt/cni/bin/
echo "====== Installed cni plugings ==========="

echo "========== Checking log file $LOGFILE =========="
tail $LOGFILE
echo "========== Checking log file $LOGFILE =========="

