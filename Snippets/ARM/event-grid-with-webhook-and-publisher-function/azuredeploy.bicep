@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@description('URL of service subscribing to events. You may use https://docs.microsoft.com/en-us/samples/azure-samples/azure-event-grid-viewer/azure-event-grid-viewer for testing.')
param eventGridWebhookSubscriptionUrl string = 'https://azure-event-grid-viewer.azurewebsites.net/api/updates'

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var templateFuncName = '${resourceNamePrefix}-template-f-${resourceNameSuffix}'
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}
var eventGridTopicName = '${resourceNamePrefix}-egt-${resourceNameSuffix}'
var eventGridWebhookSubscriptionName = 'wh-eventviewer'

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

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'pergb2018'
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
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(templateFuncRes.id, '2020-09-01', 'Full').identity.principalId
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

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource appServicePlanRes 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: resourceLocation
  sku: appServicePlanSku
  properties: {}
}

resource templateFuncRes 'Microsoft.Web/sites@2021-03-01' = {
  name: templateFuncName
  kind: 'functionapp'
  location: resourceLocation
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${templateFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${templateFuncName}.scm.azurewebsites.net'
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

resource templateFuncAppSettingsRes 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: templateFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsRes.properties.ConnectionString
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    WEBSITE_CONTENTSHARE: templateFuncName
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    EventGridTopicEndpoint: eventGridTopicRes.properties.endpoint
    EventGridTopicKey: listKeys(eventGridTopicRes.id, '2020-04-01-preview').key1
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
  ]
}

// Doc: https://learn.microsoft.com/en-us/azure/templates/microsoft.eventgrid/topics
resource eventGridTopicRes 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: eventGridTopicName
  location: resourceLocation
  properties: {
    inputSchema: 'EventGridSchema'
    publicNetworkAccess: 'Enabled'
    dataResidencyBoundary: 'WithinGeopair'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource eventGridTopicDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: eventGridTopicRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'DeliveryFailures'
        enabled: true
      }
      {
        category: 'PublishFailures'
        enabled: true
      }
      {
        category: 'DataPlaneRequests'
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

// Doc: https://learn.microsoft.com/en-us/azure/templates/microsoft.eventgrid/topics/eventsubscriptions
resource eventGridTopicWebhookSubscriptionRes 'Microsoft.EventGrid/eventSubscriptions@2022-06-15' = {
  name: eventGridWebhookSubscriptionName
  scope: eventGridTopicRes
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: eventGridWebhookSubscriptionUrl
      }
    }
    filter: {
      includedEventTypes: null
      advancedFilters: [
        {
          key: 'EventType'
          operatorType: 'StringBeginsWith'
          values: [
            'Namespace.'
          ]
        }
      ]
    }
  }
}
