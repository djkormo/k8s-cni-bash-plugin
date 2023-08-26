#!/bin/bash
##########################################################################################
# Generate the CNI configuration and move to CNI configuration directory
##########################################################################################

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

# TODO path  node with .spec.podCIDR

# kubectl patch node aks-nodepool1-38495471-vmss000006  -p '{"spec":{"podCIDR":"10.244.1.0/24"}}'  --dry-run=server -v9

node_subnet=$(curl --cacert "${KUBE_CACERT}" --header "Authorization: Bearer ${SERVICEACCOUNT_TOKEN}" -X GET "${node_resource_path}" | jq ".spec.podCIDR")

# Check if the node subnet is valid IPv4 CIDR address
ipv4_cidr_regex="(((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?))(\/([8-9]|[1-2][0-9]|3[0-2]))([^0-9.]|$)"
if [[ ${node_subnet} =~ ${ipv4_cidr_regex} ]]
then
    echo "${node_subnet} is a valid IPv4 CIDR address."
else
    echo "${node_subnet} is not a valid IPv4 CIDR address!"
    exit 1
fi

# exit if the NODE_NAME environment variable is not set.
if [[ -z "${CNI_NETWORK_CONFIG}" ]];
then
    echo "CNI_NETWORK_CONFIG not set."
    exit 1
fi

#TMP_CONF='/minicni.conf.tmp'
#cat >"${TMP_CONF}" <<EOF
#${CNI_NETWORK_CONFIG}
#EOF

## Replace the __NODE_SUBNET__
#grep "__NODE_SUBNET__" "${TMP_CONF}" && sed -i s~__NODE_SUBNET__~"${NODE_SUBNET}"~g "${TMP_CONF}"
