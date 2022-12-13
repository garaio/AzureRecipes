@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var storageAccountRegionalCodes = {
  fakeLocation: 'z0'
  westeurope: 'z6'
  switzerlandnorth: 'z1'
}
var cdnProfileName = '${resourceNamePrefix}-cdn-${resourceNameSuffix}'
var cdnEndpointName = '${resourceNamePrefix}-cdn-ep-${resourceNameSuffix}'
var cdnEndpointOriginHost = '${storageAccountName}.${storageAccountRegionalCodes[resourceLocation]}.web.${environment().suffixes.storage}'
var cdnEndpointOriginName = '${storageAccountName}-static-website'

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

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource cdnProfileRes 'Microsoft.Cdn/profiles@2020-04-15' = {
  name: cdnProfileName
  location: resourceLocation
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {
  }
}

resource cdnProfileDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: cdnProfileRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'AzureCdnAccessLog'
        enabled: true
      }
    ]
  }
}

resource cdnEndpointRes 'Microsoft.Cdn/profiles/endpoints@2020-04-15' = {
  parent: cdnProfileRes
  name: cdnEndpointName
  location: resourceLocation
  properties: {
    originHostHeader: cdnEndpointOriginHost
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    origins: [
      {
        name: cdnEndpointOriginName
        properties: {
          hostName: cdnEndpointOriginHost
          originHostHeader: cdnEndpointOriginHost
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
    optimizationType: 'GeneralWebDelivery'
    geoFilters: []
    deliveryPolicy: {
      rules: [
        {
          name: 'http2https'
          order: 1
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRequestSchemeConditionParameters'
                operator: 'Equal'
                negateCondition: false
                matchValues: [
                  'HTTP'
                ]
              }
            }
          ]
          actions: [
            {
              name: 'UrlRedirect'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRedirectActionParameters'
                redirectType: 'Moved'
                destinationProtocol: 'Https'
              }
            }
          ]
        }
        {
          name: 'SpaSubRouting'
          order: 2
          conditions: [
            {
              name: 'UrlFileExtension'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlFileExtensionMatchConditionParameters'
                operator: 'GreaterThan'
                negateCondition: true
                matchValues: [
                  '0'
                ]
                transforms: []
              }
            }
          ]
          actions: [
            {
              name: 'UrlRewrite'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRewriteActionParameters'
                sourcePattern: '/'
                destination: '/index.html'
                preserveUnmatchedPath: false
              }
            }
          ]
        }
      ]
    }
  }
  dependsOn: [
    storageAccountRes
  ]
}

resource cdnEndpointOriginRes 'Microsoft.Cdn/profiles/endpoints/origins@2020-04-15' = {
  parent: cdnEndpointRes
  name: cdnEndpointOriginName
  properties: {
    hostName: cdnEndpointOriginHost
    enabled: true
    priority: 1
    weight: 1000
    originHostHeader: cdnEndpointOriginHost
  }
}

resource cdnEndpointDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: cdnEndpointRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'CoreAnalytics'
        enabled: true
      }
    ]
  }
}

output storageAccountWebEndpoint string = reference(storageAccountRes.id, '2019-06-01', 'Full').properties.primaryEndpoints.web
