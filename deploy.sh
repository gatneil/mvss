#!/bin/bash

region=westus
r=$RANDOM
rgname=nsgguest${r}
saname=${rgname}

expiry=$(date --date="+1 day" -u -Iminutes | cut -d '+' -f 1)Z # note: a tad hacky but needed to get the date in the right format; could also probably specify the exact format via parameters to the date command

az group create -n ${rgname} -l ${region}
az storage account create -g ${rgname} -n ${saname} --sku Standard_LRS
sakey=$(az storage account show-connection-string -g ${rgname} -n ${saname} --output table | grep AccountKey | cut -d '=' -f 5)== # note: very hacky; will likely break in the future since I don't think the order of properties in the connection string is guaranteed
saskey=$(az storage account generate-sas --expiry $expiry --permissions "acdlpruw" --resource-types "sco" --services "bfqt" --account-name ${rgname} --account-key $sakey | cut -d '"' -f 2) # note: this cut is also probably a tad hacky

cp saTemplate.json sa.parameters.json

sed -i -e "s/SANAME/${saname}/g" sa.parameters.json
sed -i -e "s/SASASTOKEN/${saskey}/g" sa.parameters.json

az group deployment create -g ${rgname} --template-file azuredeploy.json --parameters @sa.parameters.json
