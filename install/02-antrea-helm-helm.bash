
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

display_usage() { 
        echo "Example of usage:" 
        echo -e "bash $me -n aks-security2023 -g rg-aks " 

        } 

while getopts n:g: option
do
case "${option}"
in
n) AKS_NAME=${OPTARG};;
g) AKS_RG=${OPTARG};;

esac
done

if [ -z "$AKS_NAME" ]
then
      echo "\$AKS_NAME is empty"
          display_usage
          exit 
else
      echo "\$AKS_NAME is NOT empty"
fi

if [ -z "$AKS_RG" ]
then
      echo "\$AKS_RG is empty"
          display_usage
          exit 1
else
      echo "\$AKS_RG is NOT empty"
fi

# get credentials for AKS cluster
az aks get-credentials --admin --name $AKS_NAME --resource-group $AKS_RG --overwrite-existing

# add helm repo for cilium
helm repo add antrea https://charts.antrea.io
helm repo update antrea

helm search repo antrea

helm show values antrea/antrea --version  1.13.0  > 02/antrea-values.yaml

helm install antrea antrea/antrea --version 1.13.0  --namespace kube-system --values 02/antrea-values.yaml \
  --wait 
# restart all non hostnetwork pods
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
