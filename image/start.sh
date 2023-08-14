#!/bin/sh


echo "Initialising CNI bash plugin"
echo "PATH: ${PATH}"
node_number=${CNI_HOSTNAME:(-3)}
k8s-cni-bash-plugin-init
echo "Node $CNI_HOSTNAME number: ${node_number}"


echo "======== Configuration ========="
cat /cni/10-k8s-cni-bash-plugin.conf
export $(cat k8s-cni-bash-plugin.env)
printenv | grep CNI
echo "======== Configuration ========="
# included via configmap
cp /tmp/k8s-cni-bash-plugin/10-k8s-cni-bash-plugin.conf /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

#sed -i 's/.x./.x./' /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

echo "====== Installed cni plugings ==========="
cp /cni/k8s-cni-bash-plugin.bash /opt/cni/bin/k8s-cni-bash-plugin
chmod +x /opt/cni/bin/k8s-cni-bash-plugin
ls -la  /opt/cni/bin/
echo "====== Installed cni plugings ==========="

echo "========== Checking log file ${CNI_LOGFILE} =========="
tail ${CNI_LOGFILE}
echo "========== Checking log file ${CNI_LOGFILE} =========="

ip route | grep cni0
