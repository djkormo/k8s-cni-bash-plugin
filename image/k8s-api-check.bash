# based on https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/
#!/bin/bash
# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc
APISERVER=$KUBERNETES_PORT_443_TCP_ADDR:$KUBERNETES_PORT_443_TCP_PORT # for AKS
APISERVER=10.0.0.1:$KUBERNETES_PORT_443_TCP_PORT # for AKS ?
# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt

echo "APISERVER: $APISERVER"
echo "SERVICEACCOUNT: $SERVICEACCOUNT"
echo "NAMESPACE: $NAMESPACE"
echo "TOKEN: $TOKEN"

# Explore the API with TOKEN
curl -v --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api
# getting node name with Token
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/nodes/$HOSTNAME

