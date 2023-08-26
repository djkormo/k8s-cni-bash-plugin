#!/bin/sh

set -o pipefail


# The environment variables used to connect to the kube-apiserver
SERVICE_ACCOUNT_PATH=/var/run/secrets/kubernetes.io/serviceaccount
SERVICEACCOUNT_TOKEN=$(cat $SERVICE_ACCOUNT_PATH/token)
KUBE_CACERT=${KUBE_CACERT:-$SERVICE_ACCOUNT_PATH/ca.crt}
KUBERNETES_SERVICE_PROTOCOL=${KUBERNETES_SERVICE_PROTOCOL-https}
echo "KUBERNETES_SERVICE_HOST: $KUBERNETES_SERVICE_HOST"
echo "KUBERNETES_SERVICE_PROTOCOL: $KUBERNETES_SERVICE_PROTOCOL"
echo "KUBERNETES_SERVICE_PORT: $KUBERNETES_SERVICE_PORT"

function exit_with_message() {
    echo "$1"
    exit 1
}

function set_node_podcidr()
{
curl -X PATCH "$1" 
     -H 'Content-Type: application/json'
     -d '{"spec":{"podCIDR":"$2"}}'
}

# Check if we're running as a k8s pod.
if [ -f "$SERVICE_ACCOUNT_PATH/token" ];
then
    # some variables should be automatically set inside a pod
    if [ -z "${KUBERNETES_SERVICE_HOST}" ]; then
        echo "KUBERNETES_SERVICE_HOST not set"
        exit 1
    fi
    if [ -z "${KUBERNETES_SERVICE_PORT}" ]; then
        echo "KUBERNETES_SERVICE_PORT not set"
        exit 1
    fi
fi

# exit if the CNI_HOSTNAME environment variable is not set.
if [[ -z "${CNI_HOSTNAME}" ]];
then
    echo "CNI_HOSTNAME not set."
    exit 1
    
fi


node_names=$(curl --cacert "${KUBE_CACERT}" --header "Authorization: Bearer ${SERVICEACCOUNT_TOKEN}" -X GET "${KUBERNETES_SERVICE_PROTOCOL}://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/" | jq -rM '.items[] |"\(.metadata.name) \(.spec.podCIDR)"' )

echo "node_names:\n$node_names"

#mapfile -t nodenumber < <( echo "$node_names" )

#for i in "${!nodenumber[@]}"; do
#    printf "$i ${nodenumber[i]} \n"
#done

node_resource_path="${KUBERNETES_SERVICE_PROTOCOL}://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/${CNI_HOSTNAME}"

echo "node_resource_path: $node_resource_path"

echo "Initialising CNI bash plugin"
#echo "PATH: ${PATH}"
node_number=${CNI_HOSTNAME:(-1)}
echo "Node $CNI_HOSTNAME number: ${node_number}"
#convert to int
#node_number=$(($node_number))
#echo "Node $CNI_HOSTNAME number: ${node_number}"

echo "======== Configuration ========="
#export $(cat k8s-cni-bash-plugin.env)
printenv | grep CNI
echo "======== Configuration ========="
# included via configmap
cp /tmp/k8s-cni-bash-plugin/10-k8s-cni-bash-plugin.conf /etc/cni/net.d/10-k8s-cni-bash-plugin.conf
echo "======== conf template ========="
cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf
sed -i "s/.x./.$node_number./" /etc/cni/net.d/10-k8s-cni-bash-plugin.conf
echo "======== conf template ater changing node number ========="
cat /etc/cni/net.d/10-k8s-cni-bash-plugin.conf
echo "====== Installed cni plugings ==========="
cp /cni/k8s-cni-bash-plugin.bash /opt/cni/bin/k8s-cni-bash-plugin
chmod +x /opt/cni/bin/k8s-cni-bash-plugin
ls -la  /opt/cni/bin/
echo "====== Installed cni plugings ==========="

echo "========== Checking log file ${CNI_LOGFILE} =========="
#tail ${CNI_LOGFILE} -n 200
echo "========== Checking log file ${CNI_LOGFILE} =========="


cp /cni/cni-add-check.bash /tmp/k8s-cni-bash-plugin/cni-add-check.bash
cp /cni/cni-del-check.bash /tmp/k8s-cni-bash-plugin/cni-del-check.bash
cp /cni/iptables-setup.bash /tmp/k8s-cni-bash-plugin/iptables-setup.bash

