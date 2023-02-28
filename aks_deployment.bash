#/bin/bash

### Variable block  ###
export GITHUB_USER="sashosotirov"
#export PAT=''
export rootname="stream4"
export aks="$rootname-task-aks"
export location="switzerlandnorth"
export resourceGroup="$rootname-rg"
export registry="$rootname-acr"

#network
export vNet="$rootname-vnet"
export addressPrefixVNet="192.168.0.0/24"
export sNet="$rootname-snet"
export addressPrefixSNet="192.168.0.0/26"
export sku=Standard


# Create Resource Group .
echo "Creating $resourceGroup in $location..."
az group create -l $location -n $resourceGroup 

# Create virtual network .
echo "Creating $vNet"
az network vnet create \
--address-prefixes $addressPrefixVNet \
--name $vNet \
--location $location \
--resource-group $resourceGroup \
--subnet-name $sNet \
--subnet-prefixes $addressPrefixSNet

wrkID=`az network vnet show -n workload-vnet -g workload-rg --query id -o tsv`
aksID=`az network vnet show -n $vNet -g $resourceGroup --query id -o tsv`

# Peer VNet to workload-vnet.
echo "Peering $vNet to workload-vnet"
az network vnet peering create \
--name Link"$vNet"ToWorkload-vnet \
--resource-group $resourceGroup \
--vnet-name $vNet \
--remote-vnet $wrkID \
--allow-vnet-access 

# Peer workload-vnet to VNet.
echo "Peering workload-vnet to $vNet"
az network vnet peering create \
--name "LinkWorkloadTo"$vNet \
--resource-group workload-rg \
--vnet-name workload-vnet \
--remote-vnet $aksID \
--allow-vnet-access 

snetID=$(az network vnet subnet show \
--resource-group $resourceGroup \
--vnet-name $vNet --name $sNet \
--query id -o tsv)

# Create azure k8s service.
echo "Creating $aks ..."
az aks create --name $aks \
--resource-group $resourceGroup \
--location $location \
--node-count 1 \
--node-vm-size Standard_DS2_v2 \
--ssh-key-value .ssh/id_rsa.pub \
--network-plugin kubenet \
--vnet-subnet-id $snetID  

# Create Container Registry .
# az acr create --name $registry \
# --resource-group $resourceGroup \
# --location $location
# --sku $sku

az aks get-credentials \
--resource-group $resourceGroup \
--name $aks \
--overwrite-existing

kubectl create namespace git
kubectl create namespace executor

# Create aks secrets
## DockerHub credentials
kubectl create secret generic dockerlogin \
--from-file=.dockerconfigjson=/home/sasho/.docker/config.json \
--type=kubernetes.io/dockerconfigjson \
--namespace="executor"
## GitHub credentials
kubectl create secret generic github-secret \
    --type=kubernetes.io/githubauth \
    --from-literal=GITHUB_USER=$GITHUB_USER \
    --from-literal=GITHUB_TOKEN=$PAT \
    --namespace="git"
              
kubectl create configmap input-data \
    --from-literal=NAME=Iva \
    --from-literal=SURNAME=Misheva \
    --from-literal=REGION=Germany \
    --namespace="executor"

# Create a storage account
az storage account create -n "$rootname"st \
-g $resourceGroup -l $location \
--sku Standard_LRS

connectionSTR=`az storage account \
show-connection-string -n "$rootname"st \
-g $resourceGroup -o tsv`

# Create the file share
az storage share create -n $rootname-share \
--connection-string $connectionSTR

# Get storage account key
strKEY=$(az storage account keys list \
--resource-group $resourceGroup \
--account-name "$rootname"st \
--query "[0].value" -o tsv)

kubectl create secret generic azure-secret \
--from-literal=azurestorageaccountname="$rootname"st \
--from-literal=azurestorageaccountkey=$strKEY \
--namespace="git"

kubectl create secret generic azure-secret \
--from-literal=azurestorageaccountname="$rootname"st \
--from-literal=azurestorageaccountkey=$strKEY \
--namespace="executor"

kubectl apply -f git-pod.yml
sleep 30
kubectl apply -f exec-pod.yml

# for debugging purposes 
kubectl logs exec-pod -n executor

