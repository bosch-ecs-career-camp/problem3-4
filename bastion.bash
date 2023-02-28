#/bin/bash

### Variable block  ###
export location="westeurope"
export resourceGroup="infra-service-rg"
#network
export vNet="infra-service-vnet"
export addressPrefixVNet="10.0.0.0/16"
export sNet="AzureBastionSubnet"
export addressPrefixSNet="10.0.0.0/24"
export sku=Standard
export bstn="infra-service-bas"

# Create Resource Group.
echo "Creating $resourceGroup in $location..."
az group create -l $location -n $resourceGroup 

# Create virtual network
echo "Creating $vNet"
az network vnet create \
--address-prefixes $addressPrefixVNet \
--name $vNet \
--resource-group $resourceGroup \
--subnet-name $sNet \
--subnet-prefixes $addressPrefixSNet

az network public-ip create \
--resource-group $resourceGroup \
--location $location \
--name "$bstn-pip" \
--sku $sku

wrkID=`az network vnet show -n workload-vnet -g workload-rg --query id -o tsv`
bsnID=`az network vnet show -n $vNet -g $resourceGroup --query id -o tsv`

# Peer bstn to workload.
az network vnet peering create \
--name bstnToWorkload \
--resource-group $resourceGroup \
--vnet-name $vNet \
--remote-vnet $wrkID \
--allow-vnet-access \
--allow-forwarded-traffic

# Peer workload to bstn.
az network vnet peering create \
--name workloadTobstn \
--resource-group workload-rg \
--vnet-name workload-vnet \
--remote-vnet $bsnID \
--allow-vnet-access 

az network bastion create \
--name $bstn \
--public-ip-address "$bstn-pip" \
--resource-group $resourceGroup \
--vnet-name $vNet \
--location $location \
--enable-tunneling \
--sku $sku                         
                         
export vm1_id=`az vm show -g workload-rg -n workload-vm1 --query id -o tsv`
export vm2_id=`az vm show -g workload-rg -n workload-vm2 --query id -o tsv`

az network bastion ssh \
--name $bstn \
--resource-group $resourceGroup \
--target-resource-id $vm2_id \
--auth-type ssh-key \
--username sasho \
--ssh-key .ssh/id_rsa


