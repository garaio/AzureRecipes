
@description('The prefix will be used for every parameter that represents a resource name. See the description of the parameter.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every resource name. You have to specify a unique, not yet used, value.')
param resourceNameSuffix string

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'

var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretServiceBusConnectionString = 'serviceBusConnectionString'

var schedulerFuncName = '${resourceNamePrefix}-scheduler-f-${resourceNameSuffix}'
var schedulerFuncPackagePath = '/FunctionApp.zip'
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
var storageAccountFunctionSasParams = {
  signedServices: 'b'
  signedResourceTypes: 'o'
  signedPermission: 'r'
  signedExpiry: '2050-01-01T00:00:00Z'
}
var storageAccountBlobUri = 'https://${storageAccountName}.blob.core.windows.net/'

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}

var serviceBusNamespaceName = '${resourceNamePrefix}-sb-${resourceNameSuffix}'
var serviceBusTriggersQueueName = 'triggers'
var serviceBusQueues = [
  serviceBusTriggersQueueName
]

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
    allowBlobPublicAccess: true
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

resource keyVaultAccessSchedulerFuncRes 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultRes.name}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(schedulerFuncRes.id, '2019-08-01', 'Full').identity.principalId
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

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultRes.name}/${keyVaultSecretStorageAccountConnectionString}'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource keyVaultSecretServiceBusConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVaultRes.name}/${keyVaultSecretServiceBusConnectionString}'
  properties: {
    value: listkeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, 'RootManageSharedAccessKey'), '2017-04-01').primaryConnectionString
  }
  dependsOn: [
    serviceBusNamespaceRes
  ]
}

resource serviceBusNamespaceRes 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
  }
}

resource serviceBusQueuesRes 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' = [for item in serviceBusQueues: {
  name: '${serviceBusNamespaceRes.name}/${item}'
  properties: {
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    enablePartitioning: false
    enableExpress: false
  }
  dependsOn: [
    serviceBusNamespaceRes
  ]
}]

resource serviceBusNamespaceDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: serviceBusNamespaceRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'OperationalLogs'
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
    serviceBusNamespaceRes
  ]
}

resource appServicePlanRes 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: appServicePlanName
  location: resourceGroup().location
  sku: appServicePlanSku
  properties: {
  }
}

resource schedulerFuncRes 'Microsoft.Web/sites@2020-09-01' = {
  name: schedulerFuncName
  kind: 'functionapp'
  location: resourceGroup().location
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${schedulerFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${schedulerFuncName}.scm.azurewebsites.net'
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
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    storageAccountRes
    appInsightsRes
  ]
}

resource processFuncAppSettingsRes 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${schedulerFuncRes.name}/appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${keyVaultSecretStorageAccountConnectionStringRes.properties.secretUriWithVersion})'
    AzureWebJobsDisableHomepage: true
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: reference('Microsoft.Insights/components/${appInsightsName}').InstrumentationKey
    APPINSIGHTS_PROFILERFEATURE_VERSION: '1.0.0'
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION: '1.0.0'
    DiagnosticServices_EXTENSION_VERSION: '~3'
    ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
    FUNCTIONS_EXTENSION_VERSION: '~3'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_RUN_FROM_PACKAGE: '${storageAccountBlobUri}${blobContainerDeployment}${schedulerFuncPackagePath}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    WEBSITE_CONTENTSHARE: schedulerFuncName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    ServiceBusConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretServiceBusConnectionString})'
    ServiceBusQueueName: serviceBusTriggersQueueName
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
    keyVaultSecretServiceBusConnectionStringRes
  ]
}

output serviceBusConnectionString string = listkeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, 'RootManageSharedAccessKey'), '2017-04-01').primaryConnectionString
