#!/bin/sh

echo "Initialising CNI bash plugin"
echo "PATH: ${PATH}"
echo "======== Configuration ========="
cat /cni/10-k8s-cni-bash-plugin.conf
echo "======== Configuration ========="

cp /cni/10-k8s-cni-bash-plugin.conf /etc/cni/net.d/10-k8s-cni-bash-plugin.conf

echo "====== Installed cni plugings ==========="
cp /cni/k8s-cni-bash-plugin.bash /opt/cni/bin/k8s-cni-bash-plugin
chmod +x /opt/cni/bin/k8s-cni-bash-plugin

ls -la  /opt/cni/bin/
echo "====== Installed cni plugings ==========="

echo "========== Checking log file $LOGFILE =========="
tail ${LOGFILE}
echo "========== Checking log file $LOGFILE =========="

brctl addbr cni0
ip link set cni0 up
ip addr add 10.245.0.1/24 dev cni0
#These commands create the bridge, enable it, and then assign an IP address to it. The last command also implicitly creates a route, so that all traffic with the destination IP belonging to the pod CIDR range, local to the current node, will be redirected to the cni0 network interface. (As mentioned before, all the other software communicates with a bridge as though it were an ordinary network interface.) You can view this implicitly created route by running the ip route command from both master and worker VMs:

ip route | grep cni0
