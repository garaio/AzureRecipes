@description('The prefix will be used for every parameter that represents a resource name. See the description of the parameter.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name. See the description of the parameter.')
param resourceNameSuffix string

@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param cognitiveSearchSku string = 'basic'
param indexerFuncScheduleExpr string = '0 */5 6-20 * * 1-6'

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretSearchServiceApiKey = 'searchServiceApiKey'

var blobContainerConfig = 'config'
var blobContainerDeployment = 'deployment'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var storageAccountBlobs = [
  {
    name: blobContainerConfig
    publicAccess: 'None'
  }
  {
    name: blobContainerDeployment
    publicAccess: 'None'
  }
]
var storageAccountBlobUri = 'https://${storageAccountName}.blob.core.windows.net/'
var storageAccountFunctionSasParams = {
  signedServices: 'b'
  signedResourceTypes: 'o'
  signedPermission: 'r'
  signedExpiry: '2050-01-01T00:00:00Z'
}

var cognitiveSearchName = '${resourceNamePrefix}-cs-${resourceNameSuffix}'

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}
var indexerFuncName = '${resourceNamePrefix}-indexer-f-${resourceNameSuffix}'
var indexerFuncPackagePath = '/Customer.Project.IndexerFuncApp.zip'
var searchFuncName = '${resourceNamePrefix}-search-f-${resourceNameSuffix}'
var searchFuncPackagePath = '/Customer.Project.SearchFuncApp.zip'

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

resource storageAccountRes 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageAccountBlobContainerRes 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for item in storageAccountBlobs: {
  name: '${storageAccountName}/default/${item.name}'
  properties: {
    publicAccess: item.publicAccess
  }
  dependsOn: [
    storageAccountRes
  ]
}]

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsightsRes 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWsRes.id
  }
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    accessPolicies: []
  }
}

resource keyVaultDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: keyVaultRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    keyVaultRes
  ]
}

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: '${keyVaultSecretStorageAccountConnectionString}'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource keyVaultSecretSearchServiceApiKeyRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: '${keyVaultSecretSearchServiceApiKey}'
  properties: {
    value: listAdminKeys(cognitiveSearchRes.id, '2020-03-13').primaryKey
  }
}

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(searchFuncRes.id, '2020-09-01', 'Full').identity.principalId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'get'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: reference(indexerFuncRes.id, '2020-09-01', 'Full').identity.principalId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource cognitiveSearchRes 'Microsoft.Search/searchServices@2020-08-01' = {
  name: cognitiveSearchName
  location: resourceGroup().location
  sku: {
    name: cognitiveSearchSku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
  }
}

resource cognitiveSearchDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: cognitiveSearchRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'OperationLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    cognitiveSearchRes
  ]
}

resource appServicePlanRes 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: appServicePlanName
  location: resourceGroup().location
  sku: appServicePlanSku
  properties: {}
}

resource searchFuncRes 'Microsoft.Web/sites@2020-09-01' = {
  name: searchFuncName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${searchFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${searchFuncName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlanRes.id
    clientAffinityEnabled: true
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource searchFuncAppSettingsRes 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: searchFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsRes.properties.InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_RUN_FROM_PACKAGE: '${storageAccountBlobUri}${blobContainerDeployment}${searchFuncPackagePath}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    WEBSITE_CONTENTSHARE: searchFuncName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    ConfigContainerName: blobContainerConfig
    SearchServiceName: cognitiveSearchName
    SearchServiceApiKey: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretSearchServiceApiKey})'
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
    keyVaultSecretSearchServiceApiKeyRes
  ]
}

resource indexerFuncRes 'Microsoft.Web/sites@2020-09-01' = {
  name: indexerFuncName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${indexerFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${indexerFuncName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlanRes.id
    clientAffinityEnabled: true
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource indexerFuncAppSettingsRes 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: indexerFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsRes.properties.InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_RUN_FROM_PACKAGE: '${storageAccountBlobUri}${blobContainerDeployment}${indexerFuncPackagePath}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    WEBSITE_CONTENTSHARE: indexerFuncName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    ConfigContainerName: blobContainerConfig
    SearchServiceName: cognitiveSearchName
    SearchServiceApiKey: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretSearchServiceApiKey})'
    ScheduleExpression: indexerFuncScheduleExpr
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
    keyVaultSecretSearchServiceApiKeyRes
  ]
}
