@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param keyVaultName string
param keyVaultResourceGroupName string
param keyVaultSecretNameStorageAccountConnectionString string = 'storageAccountConnectionString'
param keyVaultSecretNameServiceBusConnectionString string = 'serviceBusConnectionString'
param keyVaultSecretNameSignalRConnectionString string = 'signalRConnectionString'

@secure()
param appInsightsConnectionString string = ''

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}

var serviceFuncName = '${resourceNamePrefix}-service-f-${resourceNameSuffix}'

resource partnerIdRes 'Microsoft.Resources/deployments@2020-06-01' = {
  name: 'pid-d16e7b59-716a-407d-96db-18d1cac40407'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource appServicePlanRes 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: appServicePlanName
  location: resourceLocation
  sku: appServicePlanSku
  properties: {}
}

resource serviceFuncRes 'Microsoft.Web/sites@2021-03-01' = {
  name: serviceFuncName
  location: resourceLocation
  kind: 'functionapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${serviceFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${serviceFuncName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlanRes.id
    clientAffinityEnabled: true
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!empty(keyVaultName) && !empty(keyVaultResourceGroupName)) {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

module serviceFuncAppSettingsRes './modules.funcAppSettings.bicep' = if (!empty(keyVaultName) && !empty(keyVaultResourceGroupName)) {
  name: 'func-appsettings'
  params: {
    keyVaultName: keyVaultName
    serviceFuncName: serviceFuncName
    storageAccountConnectionString: keyVaultRes.getSecret(keyVaultSecretNameStorageAccountConnectionString)
    appInsightsConnectionString: appInsightsConnectionString
    keyVaultSecretNameServiceBusConnectionString: keyVaultSecretNameServiceBusConnectionString
    keyVaultSecretNameSignalRConnectionString: keyVaultSecretNameSignalRConnectionString
    keyVaultSecretNameStorageAccountConnectionString: keyVaultSecretNameStorageAccountConnectionString
  }
  dependsOn: [
    keyVaultAccessPolicyRes
  ]
}

module keyVaultAccessPolicyRes './modules.keyVaultAccessPolicy.bicep' = if (!empty(keyVaultName) && !empty(keyVaultResourceGroupName)) {
  name: 'keyvault-accesspolicy-service'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    principalId: reference(serviceFuncRes.id, '2021-03-01', 'Full').identity.principalId
  }
}
