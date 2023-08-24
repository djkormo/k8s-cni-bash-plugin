#!/bin/bash
##########################################################################################
# Generate the CNI configuration and move to CNI configuration directory
##########################################################################################

# The environment variables used to connect to the kube-apiserver
SERVICE_ACCOUNT_PATH=/var/run/secrets/kubernetes.io/serviceaccount
SERVICEACCOUNT_TOKEN=$(cat $SERVICE_ACCOUNT_PATH/token)
KUBE_CACERT=${KUBE_CACERT:-$SERVICE_ACCOUNT_PATH/ca.crt}
KUBERNETES_SERVICE_PROTOCOL=${KUBERNETES_SERVICE_PROTOCOL-https}

# Check if we're running as a k8s pod.
if [ -f "$SERVICE_ACCOUNT_PATH/token" ];
then
    # some variables should be automatically set inside a pod
    if [ -z "${KUBERNETES_SERVICE_HOST}" ]; then
        exit_with_message "KUBERNETES_SERVICE_HOST not set"
    fi
    if [ -z "${KUBERNETES_SERVICE_PORT}" ]; then
        exit_with_message "KUBERNETES_SERVICE_PORT not set"
    fi
fi

# exit if the NODE_NAME environment variable is not set.
if [[ -z "${CNI_HOSTNAME}" ]];
then
    exit_with_message "NODE_NAME not set."
fi

# TODO
# Listening all nodes, numbering tham if spec.podCIDR is not set 
NODE_RESOURCE_PATH="${KUBERNETES_SERVICE_PROTOCOL}://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/api/v1/nodes/${CNI_HOSTNAME}"
NODE_SUBNET=$(curl --cacert "${KUBE_CACERT}" --header "Authorization: Bearer ${SERVICEACCOUNT_TOKEN}" -X GET "${NODE_RESOURCE_PATH}" | jq ".spec.podCIDR")

# Check if the node subnet is valid IPv4 CIDR address
IPV4_CIDR_REGEX="(((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?))(\/([8-9]|[1-2][0-9]|3[0-2]))([^0-9.]|$)"
if [[ ${NODE_SUBNET} =~ ${IPV4_CIDR_REGEX} ]]
then
    echo "${NODE_SUBNET} is a valid IPv4 CIDR address."
else
    exit_with_message "${NODE_SUBNET} is not a valid IPv4 CIDR address!"
fi

# exit if the NODE_NAME environment variable is not set.
if [[ -z "${CNI_NETWORK_CONFIG}" ]];
then
    exit_with_message "CNI_NETWORK_CONFIG not set."
fi

#TMP_CONF='/minicni.conf.tmp'
#cat >"${TMP_CONF}" <<EOF
#${CNI_NETWORK_CONFIG}
#EOF

## Replace the __NODE_SUBNET__
#grep "__NODE_SUBNET__" "${TMP_CONF}" && sed -i s~__NODE_SUBNET__~"${NODE_SUBNET}"~g "${TMP_CONF}"
