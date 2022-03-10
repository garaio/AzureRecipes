@description('The prefix will be used for every parameter that represents a resource name. See the description of the parameter.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name. See the description of the parameter.')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param serviceBusSku string = 'Standard'

@description('Generate logic app resources based on linked templates')
param deployLogicApps bool = false

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretServiceBusConnectionString = 'ServiceBusConnectionString'

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
var storageAccountBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/'

var serviceBusNamespaceName = '${resourceNamePrefix}-sb-${resourceNameSuffix}'
var serviceBusQueues = [
  'demo'
]

var logicAppFtpDemoName = '${resourceNamePrefix}-ftp-la-${resourceNameSuffix}'
var logicAppFtpDemoDefUri = '${storageAccountBlobUri}${blobContainerDeployment}/LogicApps/ftp-demo.json'

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
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
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
  location: resourceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsightsRes 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: resourceLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWsRes.id
  }
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: resourceLocation
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
}

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource keyVaultSecretServiceBusConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: keyVaultSecretServiceBusConnectionString
  properties: {
    value: listkeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, 'RootManageSharedAccessKey'), '2017-04-01').primaryConnectionString
  }
  dependsOn: [
    serviceBusNamespaceRes
  ]
}

resource serviceBusNamespaceRes 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: serviceBusNamespaceName
  location: resourceLocation
  sku: {
    name: serviceBusSku
    tier: serviceBusSku
  }
  properties: {}
}

resource serviceBusQueuesRes 'Microsoft.ServiceBus/namespaces/queues@2021-01-01-preview' = [for item in serviceBusQueues: {
  parent: serviceBusNamespaceRes
  name: item
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
}

resource logicAppFtpDemoRes 'Microsoft.Resources/deployments@2021-01-01' = if (deployLogicApps) {
  name: logicAppFtpDemoName
  properties: {
    mode: 'Incremental'
    templateLink: {
      uri: '${logicAppFtpDemoDefUri}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    }
    parameters: {
      LogicAppName:  { 
        value: logicAppFtpDemoName
      }
    }
  }
}

resource logicAppFtpDemoDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: logicAppFtpDemoRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'WorkflowRuntime'
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
}
