@description('The prefix will be used for every parameter that represents a resource name. See the description of the parameter.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name. See the description of the parameter.')
param resourceNameSuffix string

@description('Register API with Azure Active Directory (B2C or regular) to enforce user authentication.')
param deployUserAuth bool = false

@description('Client Id of App Registration in Azure Active Directory (B2C or regular). Required when parameter \'deployUserAuth\' is set to true.')
param serviceAppId string = ''

@description('Azure AD B2C domain name. Required when parameter \'deployUserAuth\' is set to true.')
param aadB2cName string = ''

@description('For production deployments use Premium App Service Plan which provides lower latency thanks to pre-warmed instances.')
param usePremiumFunctionPlan bool = false

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretCosmosDbConnectionString = 'cosmosDbConnectionString'

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
var storageAccountRegionalCodes = {
  fakeLocation: 'z0'
  westeurope: 'z6'
  switzerlandnorth: 'z1'
}

var cdnProfileName = '${resourceNamePrefix}-cdn-${resourceNameSuffix}'
var cdnEndpointName = '${resourceNamePrefix}-cdn-ep-${resourceNameSuffix}'
var cdnEndpointOriginHost = '${storageAccountName}.${storageAccountRegionalCodes[resourceGroup().location]}.web.core.windows.net'
var cdnEndpointOriginName = '${storageAccountName}-static-website'

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var serviceFuncName = '${resourceNamePrefix}-service-f-${resourceNameSuffix}'
var serviceFuncPackagePath = '/Customer.Project.ServiceFuncApp.zip'

var cosmosDbAccountName = '${resourceNamePrefix}-cdb-${resourceNameSuffix}'

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

resource keyVaultSecretCosmosDbConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: '${keyVaultSecretCosmosDbConnectionString}'
  properties: {
    value: listConnectionStrings(cosmosDbAccountRes.id, '2020-04-01').connectionStrings[0].connectionString
  }
}

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(serviceFuncRes.id, '2019-08-01', 'Full').identity.principalId
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

resource cosmosDbAccountRes 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: cosmosDbAccountName
  location: resourceGroup().location
  tags: {
    defaultExperience: 'Core (SQL)'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    enableFreeTier: false
    enableAnalyticalStorage: false
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: resourceGroup().location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
      }
    }
  }
}

resource cosmosDbAccountDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: cosmosDbAccountRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
  dependsOn: [
    cosmosDbAccountRes
  ]
}

resource appServicePlanConsumptionRes 'Microsoft.Web/serverfarms@2020-09-01' = if (!usePremiumFunctionPlan) {
  name: (usePremiumFunctionPlan ? uniqueString(resourceGroup().id) : appServicePlanName)
  location: resourceGroup().location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource appServicePlanPremiumRes 'Microsoft.Web/serverfarms@2020-09-01' = if (usePremiumFunctionPlan) {
  name: (usePremiumFunctionPlan ? appServicePlanName : uniqueString(resourceGroup().id))
  location: resourceGroup().location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
  }
}

resource serviceFuncRes 'Microsoft.Web/sites@2020-09-01' = {
  name: serviceFuncName
  location: resourceGroup().location
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
    serverFarmId: resourceId('Microsoft.Web/serverfarms', appServicePlanName)
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
    appServicePlanConsumptionRes
    appServicePlanPremiumRes
  ]
}

resource serviceFuncAppSettingsRes 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: serviceFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsRes.properties.InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_RUN_FROM_PACKAGE: '${storageAccountBlobUri}${blobContainerDeployment}${serviceFuncPackagePath}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    WEBSITE_CONTENTSHARE: serviceFuncName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    CosmosDbConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretCosmosDbConnectionString})'
    ConfigContainerName: blobContainerConfig
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
    keyVaultSecretCosmosDbConnectionStringRes
  ]
}

resource serviceFuncAuthSettingsRes 'Microsoft.Web/sites/config@2020-09-01' = if (deployUserAuth) {
  parent: serviceFuncRes
  name: 'authsettings'
  properties: {
    enabled: true
    unauthenticatedClientAction: 'RedirectToLoginPage'
    defaultProvider: 'AzureActiveDirectory'
    clientId: serviceAppId
    issuer: (empty(aadB2cName) ? 'https://login.microsoftonline.com/${subscription().tenantId}' : 'https://${aadB2cName}.b2clogin.com/${aadB2cName}.onmicrosoft.com/v2.0/.well-known/openid-configuration?p=B2C_1_signupsignin')
  }
}

resource cdnProfileRes 'Microsoft.Cdn/profiles@2020-04-15' = {
  name: cdnProfileName
  location: resourceGroup().location
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {}
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
  dependsOn: [
    cdnProfileRes
  ]
}

resource cdnEndpointRes 'Microsoft.Cdn/profiles/endpoints@2020-04-15' = {
  parent: cdnProfileRes
  name: '${cdnEndpointName}'
  location: resourceGroup().location
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
  dependsOn: [
    cdnEndpointRes
  ]
}

output storageAccountWebEndpoint string = reference(storageAccountRes.id, '2019-06-01', 'Full').properties.primaryEndpoints.web
