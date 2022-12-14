@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@description('If set to false, it deploys the KeyVault as fresh new instance including removal of all other access policies. If set to true, the KeyVault needs to be existing, otherwise an error is thrown.')
param useExistingKeyVault bool = true

@description('Object ID of service principal used with DevOps Service Connection to deploy resources. This is added to the KeyVault with read rights so that secrets can be gathered in pipeline runs using same Service Connection.')
param servicePrincipalId string = ''

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'

var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultAppPermissions = {
  keys: [
    'get'
  ]
  secrets: [
    'get'
  ]
}
var keyVaultSecretNameStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretNameAppInsightsConnectionString = 'appInsightsConnectionString'
var keyVaultSecretNameServiceBusConnectionString = 'serviceBusConnectionString'

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

var serviceBusNamespaceName = '${resourceNamePrefix}-sb-${resourceNameSuffix}'

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

resource appInsightsRes 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: resourceLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWsRes.id
  }
}

resource serviceBusNamespaceRes 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusNamespaceName
  location: resourceLocation
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
  }
}

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

resource keyVaultRes 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    enableSoftDelete: true // With default of softDeleteRetentionInDays = 90
    createMode: useExistingKeyVault ? 'recover' : 'default'
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

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: union(empty(servicePrincipalId) ? [] : [ 
      {
        tenantId: subscription().tenantId
        objectId: servicePrincipalId
        permissions: keyVaultAppPermissions
      } 
    ], [
    ])
  }
}

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretNameStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource keyVaultSecretServiceBusConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretNameServiceBusConnectionString
  properties: {
    value: listkeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', serviceBusNamespaceName, 'RootManageSharedAccessKey'), '2021-11-01').primaryConnectionString
  }
}

resource keyVaultSecretAppInsightsConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretNameAppInsightsConnectionString
  properties: {
    value: appInsightsRes.properties.ConnectionString
  }
}
