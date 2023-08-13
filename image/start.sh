#!/bin/sh


echo "Initialising CNI bash plugin"
echo "PATH: ${PATH}"

echo "======== Configuration ========="
cat /cni/10-k8s-cni-bash-plugin.conf
export $(cat k8s-cni-bash-plugin.env)
printenv | grep CNI
echo "======== Configuration ========="

cp /cni/10-k8s-cni-bash-plugin.conf /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

echo "====== Installed cni plugings ==========="
cp /cni/k8s-cni-bash-plugin.bash /opt/cni/bin/k8s-cni-bash-plugin
chmod +x /opt/cni/bin/k8s-cni-bash-plugin
ls -la  /opt/cni/bin/
echo "====== Installed cni plugings ==========="

echo "========== Checking log file ${CNI_LOGFILE} =========="
tail ${CNI_LOGFILE}
echo "========== Checking log file ${CNI_LOGFILE} =========="

ip route | grep cni0
