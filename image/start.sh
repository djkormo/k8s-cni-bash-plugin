#!/bin/bash

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
curl_patch="curl --cacert \"${KUBE_CACERT}\" --request PATCH "$1"  --header 'Content-Type: application/json-patch+json' --header \"Authorization: Bearer ${SERVICEACCOUNT_TOKEN}\"  --data '[{\"op\": \"replace\", \"path\": \"/spec/podCIDR\", \"value\":\"$2\"}]'"
echo "curl_patch: $curl_patch"
eval $curl_patch
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


# TODO
# Listening all nodes, numbering tham if spec.podCIDR is not set 

node_names=$(curl --cacert "${KUBE_CACERT}" --header "Authorization: Bearer ${SERVICEACCOUNT_TOKEN}" -X GET "${KUBERNETES_SERVICE_PROTOCOL}://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/" | jq -rM '.items[] |"\(.metadata.name) \(.spec.podCIDR)"' )

echo "node_names: $node_names"

mapfile -t nodenumber < <( echo "$node_names" )

for i in "${!nodenumber[@]}"; do
    printf "$i ${nodenumber[i]} \n"
done


node_resource_path="${KUBERNETES_SERVICE_PROTOCOL}://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/${CNI_HOSTNAME}"
# take last four characters
node_number=${CNI_HOSTNAME:(-4)}
# convert to hex
node_number=$(echo "${node_number}"| tr -d '\n' | xxd -ps -c 200 )
# convert to decimal
node_number=$((16#$node_number))
# modulu 255
node_number=$(expr $node_number % 255)
echo "Node $CNI_HOSTNAME number: ${node_number}"
# converting to int
node_number=$(expr $node_number + 0)
echo "Node $CNI_HOSTNAME number: ${node_number}"
node_pod_cidr="10.244.${node_number}.0/24"

# Check if the node subnet is valid IPv4 CIDR address
ipv4_cidr_regex="(((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?))(\/([8-9]|[1-2][0-9]|3[0-2]))([^0-9.]|$)"

if [[ ${node_pod_cidr} =~ ${ipv4_cidr_regex} ]]
then
    echo "${node_pod_cidr} is a valid IPv4 CIDR address."
else
    echo "${node_pod_cidr} is not a valid IPv4 CIDR address!"
    exit 1
fi

echo "patching node CNI_HOSTNAME with podCIDR: $node_pod_cidr"

curl_patch="curl --cacert \"${KUBE_CACERT}\" --request PATCH "${node_resource_path}"  --header 'Content-Type: application/json-patch+json' --header \"Authorization: Bearer ${SERVICEACCOUNT_TOKEN}\"  --data '[{\"op\": \"replace\", \"path\": \"/spec/podCIDR\", \"value\":\"$node_pod_cidr\"}]'"

echo "curl_patch: $curl_patch"

eval $curl_patch

# TODO path  node with .spec.podCIDR

# kubectl patch node aks-nodepool1-38495471-vmss000006  -p '{"spec":{"podCIDR":"10.244.1.0/24"}}'  --dry-run=server -v9

node_subnet=$(curl --cacert "${KUBE_CACERT}" --header "Authorization: Bearer ${SERVICEACCOUNT_TOKEN}" -X GET "${node_resource_path}" | jq ".spec.podCIDR")


if [[ ${node_subnet} =~ ${ipv4_cidr_regex} ]]
then
    echo "${node_subnet} is a valid IPv4 CIDR address."
else
    echo "${node_subnet} is not a valid IPv4 CIDR address!"
    exit 1
fi

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


cp /cni/cni-add-check.sh /tmp/k8s-cni-bash-plugin/cni-add-check.sh
cp /cni/cni-del-check.sh /tmp/k8s-cni-bash-plugin/cni-del-check.sh
cp /cni/iptables-setup.sh /tmp/k8s-cni-bash-plugin/iptables-setup.sh

