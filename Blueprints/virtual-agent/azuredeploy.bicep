@description('The prefix will be used for every parameter that represents a resource name. See the description of the parameter.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name. See the description of the parameter.')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@allowed([
  'F0'
  'S1'
])
param botSku string = 'F0'

@description('Client ID of the App Registration')
param botAppId string

@description('Client secret of the App Registration')
@secure()
param botAppSecret string

@description('Name displayed in the chat window')
param botDisplayName string = 'GARAIO-Blueprint'

@description('ID of the LUIS application (empty on initial deployment)')
param luisAppId string

@allowed([
  'F0'
  'S0'
])
param luisSku string = 'F0'

@allowed([
  'westus'
  'westeurope'
])
param luisLocation string = 'westeurope'

@description('API key to manage and edit knowledge base with indexer function, displayed on https://www.qnamaker.ai/UserSettings (empty on initial deployment)')
@secure()
param qnaApiKey string

@description('ID of the QnA Maker knowledge base (empty on initial deployment)')
param qnaKnowledgebaseId string

@allowed([
  'westus'
  'southcentralus'
  'northeurope'
])
param qnaMakerLocation string = 'northeurope'

@allowed([
  'F0'
  'S0'
])
param qnaMakerSku string = 'F0'

@allowed([
  'free'
  'basic'
  'standard'
])
param qnaSearchSku string = 'free'

@allowed([
  'F0'
  'S'
  'S0'
  'S1'
  'S2'
  'S3'
  'S4'
])
param textAnalyticsSku string = 'F0'

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretCosmosDbConnectionString = 'cosmosDbConnectionString'
var keyVaultSecretBotAppSecret = 'botAppSecret'

var blobContainerConfig = 'config'
var blobContainerDeployment = 'deployment'
var blobContainerQnaData = 'qna'
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
  {
    name: blobContainerQnaData
    publicAccess: 'None'
  }
]
var storageAccountBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/'
var storageAccountFunctionSasParams = {
  signedServices: 'b'
  signedResourceTypes: 'o'
  signedPermission: 'r'
  signedExpiry: '2050-01-01T00:00:00Z'
}

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'B1'
  tier: 'Basic' // For information, can be removed
}
var indexerFuncName = '${resourceNamePrefix}-indexer-f-${resourceNameSuffix}'
var indexerFuncPackagePath = '/Customer.Project.IndexerFuncApp.zip'
var indexerFuncJobsSchedule = '0 30 0 * * 1-5'

var botName = '${resourceNamePrefix}-wab-${resourceNameSuffix}'
var botSiteName = '${resourceNamePrefix}-wab-${resourceNameSuffix}'
var botEndpoint = 'https://${botSiteName}.azurewebsites.net/api/messages'

var cosmosDbAccountName = '${resourceNamePrefix}-cdb-${resourceNameSuffix}'

var textAnalyticsName = '${resourceNamePrefix}-ta-${resourceNameSuffix}'
var textAnalyticsEndpointHostName = 'https://${resourceLocation}.api.cognitive.microsoft.com'
var luisPredictionName = '${resourceNamePrefix}-luis-${resourceNameSuffix}'
var luisAuthoringName = '${resourceNamePrefix}-luis-auth-${resourceNameSuffix}'
var luisEndpointHostName = 'https://${luisLocation}.api.cognitive.microsoft.com'
var qnaMakerName = '${resourceNamePrefix}-qna-${resourceNameSuffix}'
var qnaSearchName = '${resourceNamePrefix}-qna-cs-${resourceNameSuffix}'
var qnaEndpointHostName = 'https://${qnaMakerName}.cognitiveservices.azure.com/qnamaker/v5.0-preview.1'

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

resource keyVaultSecretCosmosDbConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: keyVaultSecretCosmosDbConnectionString
  properties: {
    value: listConnectionStrings(cosmosDbAccountRes.id, '2020-04-01').connectionStrings[0].connectionString
  }
}

resource keyVaultSecretBotAppSecretRes 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVaultRes
  name: keyVaultSecretBotAppSecret
  properties: {
    value: botAppSecret
  }
}

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(botSiteRes.id, '2021-03-01', 'Full').identity.principalId
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
        objectId: reference(indexerFuncRes.id, '2021-03-01', 'Full').identity.principalId
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

resource cosmosDbAccountRes 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: cosmosDbAccountName
  location: resourceLocation
  kind: 'GlobalDocumentDB'
  properties: {
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    enableFreeTier: false // Not supported with serverless tier
    enableAnalyticalStorage: false
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: resourceLocation
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
      type: 'Continuous'
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
}

resource botNameRes 'Microsoft.BotService/botServices@2021-03-01' = {
  name: botName
  location: resourceLocation
  sku: {
    name: botSku
  }
  kind: 'sdk'
  properties: {
    displayName: botDisplayName
    endpoint: botEndpoint
    msaAppId: botAppId
    developerAppInsightsApplicationId: appInsightsName
    developerAppInsightKey: reference(appInsightsRes.id, '2015-05-01').InstrumentationKey
  }
  dependsOn: [
    botSiteRes
  ]
}

resource appServicePlanRes 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: resourceLocation
  sku: appServicePlanSku
  properties: {}
}

resource botSiteRes 'Microsoft.Web/sites@2021-03-01' = {
  name: botSiteName
  location: resourceLocation
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanRes.id
    siteConfig: {
      cors: {
        allowedOrigins: [
          'https://botservice.hosting.portal.azure.net'
          'https://botservice-ms.hosting.portal.azure.net'
          'https://hosting.onecloud.azure-test.net/'
        ]
      }
      alwaysOn: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource botSiteAppSettingsRes 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: botSiteRes
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsRes.properties.InstrumentationKey
    WEBSITE_NODE_DEFAULT_VERSION: '10.14.1'
    MicrosoftAppId: botAppId
    MicrosoftAppPassword: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretBotAppSecret})'
    BotDisplayName: botDisplayName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    CosmosDbConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretCosmosDbConnectionString})'
    StorageQnaDataContainerName: blobContainerQnaData
    LuisApiKeyDe: listKeys(luisPredictionRes.id, '2017-04-18').key1
    LuisAppIdDe: luisAppId
    LuisEndpointHostNameDe: luisEndpointHostName
    QnaKnowledgebaseId: qnaKnowledgebaseId
    QnaApiKey: qnaApiKey
    QnaEndpointHostName: qnaEndpointHostName
    TextAnalyticsApiKey: listKeys(textAnalyticsRes.id, '2017-04-18').key1
    TextAnalyticsEndpointHostName: textAnalyticsEndpointHostName
  }
  dependsOn: [
    keyVaultSecretBotAppSecretRes
    keyVaultSecretStorageAccountConnectionStringRes
    keyVaultSecretCosmosDbConnectionStringRes
  ]
}

resource indexerFuncRes 'Microsoft.Web/sites@2021-03-01' = {
  name: indexerFuncName
  location: resourceLocation
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

resource indexerFuncAppSettingsRes 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: indexerFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsRes.properties.InstrumentationKey
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_RUN_FROM_PACKAGE: '${storageAccountBlobUri}${blobContainerDeployment}${indexerFuncPackagePath}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    WEBSITE_CONTENTSHARE: indexerFuncName
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    ConfigContainerName: blobContainerConfig
    QnaDataContainerName: blobContainerQnaData
    QnaSubscriptionKey: listKeys(qnaMakerRes.id, '2017-04-18').key1
    QnaKnowledgebaseId: qnaKnowledgebaseId
    JobsSchedule: indexerFuncJobsSchedule
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
  ]
}

resource qnaSearchRes 'Microsoft.Search/searchServices@2015-08-19' = {
  name: qnaSearchName
  location: qnaMakerLocation
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
  sku: {
    name: qnaSearchSku
  }
}

resource qnaMakerRes 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: qnaMakerName
  kind: 'QnAMaker.v2'
  location: qnaMakerLocation
  sku: {
    name: qnaMakerSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiProperties: {
      qnaAzureSearchEndpointId: qnaSearchRes.id
      qnaAzureSearchEndpointKey: listadminkeys(qnaSearchRes.id, '2015-08-19').primaryKey
    }
    customSubDomainName: qnaMakerName
  }
}

resource luisPredictionRes 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: luisPredictionName
  kind: 'LUIS'
  location: luisLocation
  sku: {
    name: luisSku
  }
  properties: {}
}

resource luisAuthoringRes 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: luisAuthoringName
  location: luisLocation
  sku: {
    name: 'F0'
  }
  kind: 'LUIS.Authoring'
  properties: {}
}

resource textAnalyticsRes 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: textAnalyticsName
  location: resourceLocation
  sku: {
    name: textAnalyticsSku
  }
  kind: 'TextAnalytics'
  properties: {}
}
