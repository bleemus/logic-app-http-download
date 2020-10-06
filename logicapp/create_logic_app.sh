region=eastus
prefix=logicapptest
rg=$prefix-rg

### create resource group
az group create -n $rg -l $region

### create website to host
webapp=$prefix-webapp
az appservice plan create -g $rg -n $prefix-plan --is-linux --sku P1V2
az webapp create -g $rg -p $prefix-plan -n $webapp --runtime "python|3.6"
# TODO: deploy python web app

### create key vault and certificate
keyvault=$prefix-akv
az keyvault create -g $rg -l $region -n $prefix-akv --sku standard
az ad sp create-for-rbac --create-cert --keyvault $keyvault --cert logicapptest-certificate

# MANUAL STEP: assign MSI to logic app

# give new MSI for the logic app permissions to key vault
msi=$(az logic workflow list | jq --arg logicapp $logicapp '.[] | select(.name == $logicapp) | .identity.principalId' -r)
az keyvault set-policy -g $rg -n $keyvault --certificate-permissions get list --object-id $msi

### create storage account to save files to
storage_account=$prefix"account"
az storage account create -g $rg -n $storage_account -l $region --sku Standard_LRS
az storage container create -g $rg -n data --account-name $storage_account

# give managed service identity rights to write to the storage account
az role assignment create --role "Storage Blob Data Contributor" --scope $(az storage account show --name $storage_account -g $rg | jq .id -r) --assignee $msi

### create logic app

# replace URIs in logic app definition
sed -i 's/__$$WEBAPPNAME$$__/'$webapp'/g' logic_app.json
sed -i 's/__$$STORAGEACCOUNTNAME$$__/'$storage_account'/g' logic_app.json
sed -i 's/__$$KEYVAULTNAME$$__/'$keyvault'/g' logic_app.json

# create virtual network for ISE
logicapp=$prefix-loapp
vnet=$prefix-vnet

az network vnet create -g $rg -n $vnet --address-prefixes 10.1.0.0/16

# ISE requires 4 dedicated subnets
az network vnet subnet create -n subnet1 -g $rg --vnet-name $vnet --address-prefixes 10.1.0.0/24
az network vnet subnet create -n subnet2 -g $rg --vnet-name $vnet --address-prefixes 10.1.1.0/24
az network vnet subnet create -n subnet3 -g $rg --vnet-name $vnet --address-prefixes 10.1.2.0/24
az network vnet subnet create -n subnet4 -g $rg --vnet-name $vnet --address-prefixes 10.1.3.0/24

az extension add --name logic

## MANUAL STEP
# create ISE -- do this via portal, name is logicapptest-ise
ise=$prefix-ise

# awaiting fix for integration-service-environment https://github.com/Azure/azure-cli-extensions/pull/2450
# az logic workflow create -g $rg -n $prefix-lawf -l $region --integration-service-environment $ise --definition logic_app.json

# until then, create logic app from scratch and paste in logic_app.json