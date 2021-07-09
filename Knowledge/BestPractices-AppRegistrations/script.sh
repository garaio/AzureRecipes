#!/bin/bash

az login --allow-no-subscriptions

appId=$(az ad app create --display-name "Azure Recipes App" --available-to-other-tenants true --reply-urls "https://app.getpostman.com/oauth2/callback" "https://function.azurewebsites.net/.auth/login/aad/callback"  --required-resource-accesses requiredResourceAccess.json --query appId -o tsv)

appSecret=$(az ad app credential reset --id $appId --append --credential-description "Service PROD" --end-date "2099-12-31" --query password -o tsv)

echo "--- Copy following values"

echo "TenantId=$(az account show --query "tenantId" -o tsv)"
echo "ClientId=$appId"
echo "ClientSecret=$appSecret"

echo "--- Press  [ENTER] to close"
read continue