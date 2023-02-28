#/bin/bash

### Variable block  ###
export location="westeurope"
export resourceGroup="workload-rg"
#network
export vNet="workload-vnet"
export addressPrefixVNet="10.4.0.0/16"
export sNet="workload-snet"
export addressPrefixSNet="10.4.0.0/24"
export sku=Standard

#virtual machines
export vm1="workload-vm1"
export vm2="workload-vm2"
export image="UbuntuLTS"

# Create Resource Group.
echo "Creating $resourceGroup in $location..."
az group create -l $location -n $resourceGroup 

# Create virtual network .
echo "Creating $vNet"
az network vnet create \
--address-prefixes $addressPrefixVNet \
--name $vNet \
--resource-group $resourceGroup \
--subnet-name $sNet \
--subnet-prefixes $addressPrefixSNet

# Create virtual machines .
echo "Creating $vm1"
az vm create \
  --resource-group $resourceGroup \
  --name $vm1 \
  --image UbuntuLTS \
  --location $location \
  --vnet-name $vNet \
  --subnet $sNet \
  --admin-username sasho \
  --ssh-key-values .ssh/id_rsa.pub \
  --public-ip-sku $sku \
  --public-ip-address "" \
  --output table
 
  
echo "Creating $vm2"
az vm create \
  --resource-group $resourceGroup \
  --name $vm2 \
  --image UbuntuLTS \
  --location $location \
  --vnet-name $vNet \
  --subnet $sNet \
  --admin-username sasho \
  --ssh-key-values .ssh/id_rsa.pub \
  --public-ip-sku $sku \
  --public-ip-address "" \
  --output table


# Create network security group .
# az network nsg create -g $resourceGroup -n bstn-nsg

# az network nsg rule create \
# --name onlyBastionAccsses \
# --nsg-name bstn-nsg \
# --resource-group $resourceGroup \
# --priority 500 \
# --destination-port-ranges '*' \
# --destination-address-prefixes '*' \
# --source-port-ranges 22 \
# --source-address-prefixes 10.0.0.0/24

# az network vnet subnet update \
# --resource-group $resourceGroup \
# --vnet-name $vNet \
# --name $sNet \
# --network-security-group bstn-nsg

# IP=`az network public-ip show -g $resourceGroup -n "$vm1-pip" --query ipAddress -o tsv`
# ssh -o "StrictHostKeyChecking no" $IP
# ssh $IP





