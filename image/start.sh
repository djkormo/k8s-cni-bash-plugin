#!/bin/sh


echo "Initialising CNI bash plugin"
echo "PATH: ${PATH}"

echo "======== Configuration ========="
cat /cni/10-k8s-cni-bash-plugin.conf
export $(cat 10-k8s-cni-bash-plugin.env)
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

# Create bridge only if it doesn't yet exist
if ! ip link show cni0 &>/dev/null; then
    ip link add cni0 type bridge
    #ip address add "$bridge_ip"/"${pod_subnet#*/}" dev cni0
    ip address add 10.240.0.1/24 dev cni0
    ip link set cni0 up
fi

#brctl addbr cni0
#ip link set cni0 up
# todo address from env variables 
#ip addr add 10.240.0.1/24 dev cni0
#These commands create the bridge, enable it, and then assign an IP address to it. The last command also implicitly creates a route, so that all traffic with the destination IP belonging to the pod CIDR range, local to the current node, will be redirected to the cni0 network interface. (As mentioned before, all the other software communicates with a bridge as though it were an ordinary network interface.) You can view this implicitly created route by running the ip route command from both master and worker VMs:

ip route | grep cni0
