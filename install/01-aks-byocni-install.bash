#!/bin/bash

# based on https://docs.microsoft.com/en-us/azure/container-instances/container-instances-using-azure-container-registry


# -o create ,delete ,status. shutdown
# -n aks-name
# -g aks-rg
# set your name and resource group

# aks-network-policy-cilium-install.bash -n aks-security2023 -g rg-aks -l northeurope -o create

me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

display_usage() { 
        echo "Example of usage:" 
        echo -e "bash $me -n aks-cni-test2023 -g rg-aks -l northeurope -o create" 
        echo -e "bash $me -n aks-cni-test2023  -g rg-aks -l northeurope -o stop" 
        echo -e "bash $me -n aks-cni-test2023  -g rg-aks -l northeurope -o start" 
        echo -e "bash $me -n aks-cni-test2023  -g rg-aks -l northeurope -o status" 
        echo -e "bash $me -n aks-cni-test2023  -g rg-aks -l northeurope -o delete" 
        } 

while getopts n:g:o:l: option
do
case "${option}"
in
n) AKS_NAME=${OPTARG};;
g) AKS_RG=${OPTARG};;
o) AKS_OPERATION=${OPTARG};;
l) AKS_LOCATION=${OPTARG};;
esac
done


if [ -z "$AKS_OPERATION" ]
then
      echo "\$AKS_OPERATION is empty"
          display_usage
          exit 1
else
      echo "\$AKS_OPERATION is NOT empty"
fi

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

if [ -z "$AKS_LOCATION" ]
then
      echo "\$AKS_LOCATION is empty"
          display_usage
          exit 1
else
      echo "\$AKS_LOCATION is NOT empty"
fi

set -u
set -e

az aks get-versions -l $AKS_LOCATION #--query 'orchestrators[-1].orchestratorVersion' -o tsv

#AKS_VERSION=$(az aks get-versions -l $AKS_LOCATION --query 'orchestrators[-3].orchestratorVersion' -o tsv)

AKS_NODES=2

AKS_VM_SIZE=Standard_B2s
#AKS_VM_SIZE=Standard_DS3_v2

echo "AKS_NAME: $AKS_NAME"
echo "AKS_LOCATION: $AKS_LOCATION"
echo "AKS_NODES: $AKS_NODES"
#echo "AKS_VERSION: $AKS_VERSION"
echo "AKS_VM_SIZE: $AKS_VM_SIZE"

az account list -o table

echo  "az account set --subscription=REDACTED"

if [ "$AKS_OPERATION" = "create" ] ;
then

    echo "Creating AKS cluster...";

    # Create a resource group
    az group create --name $AKS_RG --location $AKS_LOCATION

   # Create a VNet with a subnet for nodes and a subnet for pods

    az network vnet create -g $AKS_RG --location $AKS_LOCATION --name "vnet_${AKS_NAME}" --address-prefixes 10.0.0.0/8 -o none 
    az network vnet subnet create -g $AKS_RG --vnet-name "vnet_${AKS_NAME}" --name nodesubnet --address-prefixes 10.240.0.0/16 -o none 
    az network vnet subnet create -g $AKS_RG --vnet-name "vnet_${AKS_NAME}" --name podsubnet --address-prefixes 10.241.0.0/16 -o none

    # Get the virtual network resource ID
    VNET_ID=$(az network vnet show --resource-group $AKS_RG --name "vnet_$AKS_NAME" --query id -o tsv)

    # Get the virtual network subnet resource ID
    NODE_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_RG --vnet-name "vnet_${AKS_NAME}" --name "nodesubnet" --query id -o tsv)

    # Get the virtual network subnet resource ID
    POD_SUBNET_ID=$(az network vnet subnet show --resource-group $AKS_RG --vnet-name "vnet_${AKS_NAME}" --name "nodesubnet" --query id -o tsv)

     echo "VNET_ID: $VNET_ID" 
     echo "NODE_SUBNET_ID: $NODE_SUBNET_ID" 
     echo "POD_SUBNET_ID: $POD_SUBNET_ID" 

      # --network-plugin none > BYOCNI -> cilium 
      
      az aks create -n $AKS_NAME -g $AKS_RG -l $AKS_LOCATION \
      
      --node-vm-size $AKS_VM_SIZE \
      --node-count $AKS_NODES \
      --max-pods 250 \
      --network-plugin none #\
      #--kubernetes-version $AKS_VERSION \
     # --vnet-subnet-id $NODE_SUBNET_ID


fi # of create


if [ "$AKS_OPERATION" = "start" ] ;

then
echo "starting VMs...";
  # get the resource group for VMs
  
  RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
  echo "RG_VM_POOL: $RG_VM_POOL"
  
  az vm list -d -g $RG_VM_POOL  | grep powerState 
  az vm start --ids $(az vm list -g $RG_VM_POOL --query "[].id" -o tsv) --no-wait

fi
 
if [ "$AKS_OPERATION" = "stop" ] ;

then
echo "stopping VMs...";
  # get the resource group for VMs
  RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)

  echo "RG_VM_POOL: $RG_VM_POOL"

  az vm list -d -g $RG_VM_POOL  | grep powerState

  az vm deallocate --ids $(az vm list -g $RG_VM_POOL --query "[].id" -o tsv) --no-wait

fi


if [ "$AKS_OPERATION" = "status" ] ;

then
  echo "AKS cluster status"
  az aks show --name $AKS_NAME --resource-group $AKS_RG
  
  # get the resource group for VMs
  RG_VM_POOL=$(az aks show -g $AKS_RG -n $AKS_NAME --query nodeResourceGroup -o tsv)
  echo "RG_VM_POOL: $RG_VM_POOL"
  
  az vm list -d -g $RG_VM_POOL  | grep powerState 
  
fi 


if [ "$AKS_OPERATION" = "delete" ] ;
then
  echo "AKS cluster deleting ";
  az aks delete --name $AKS_NAME --resource-group $AKS_RG

fi
