#!/bin/sh

echo "Initialising CNI bash plugin"
echo "======== Configuration ========="
cat 10-k8s-cni-bash-plugin.conf
echo "======== Configuration ========="
cp 10-k8s-cni-bash-plugin.conf /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

cp k8s-cni-bash-plugin.bash /opt/cni/bin/k8s-cni-bash-plugin
chmod +x /opt/cni/bin/k8s-cni-bash-plugin
"====== Installed cni plugings ==========="
ls -la  /opt/cni/bin/
"====== Installed cni plugings ==========="

