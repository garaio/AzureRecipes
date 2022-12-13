param keyVaultName string
param serviceFuncName string

@secure()
param appInsightsInstrumentationKey string
@secure()
param storageAccountConnectionString string

param keyVaultSecretNameStorageAccountConnectionString string
param keyVaultSecretNameServiceBusConnectionString string
param keyVaultSecretNameSignalRConnectionString string

resource serviceFuncRes 'Microsoft.Web/sites@2021-03-01' existing = {
  name: serviceFuncName
}

resource serviceFuncAppSettingsRes 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: serviceFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretNameStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsInstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_CONTENTSHARE: serviceFuncName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretNameStorageAccountConnectionString})'
    SignalRConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretNameSignalRConnectionString})'
    ServiceBusConncectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretNameServiceBusConnectionString})'
  }
}
