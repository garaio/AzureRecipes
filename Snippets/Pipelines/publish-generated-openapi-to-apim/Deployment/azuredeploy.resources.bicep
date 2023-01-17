@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@allowed([
  'Developer'
  'Basic'
])
param apiMgmtSku string = 'Developer'
param apiMgmtPublisherEmail string = 'info@garaio.com'
param apiMgmtPublisherName string = 'Customer AG'
param apiMgmtGatewayCustomDomain string = ''

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
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'

var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var storageAccountBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/'
var storageAccountFunctionSasParams = {
  signedServices: 'b'
  signedResourceTypes: 'o'
  signedPermission: 'r'
  signedExpiry: '2050-01-01T00:00:00Z'
}

var blobContainerDeployment = 'deployment'

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}

var demoFuncName = '${resourceNamePrefix}-demo-f-${resourceNameSuffix}'
var demoFuncPackagePath = '/DemoFuncApp.zip'

var apiMgmtName = '${resourceNamePrefix}-apim-${resourceNameSuffix}'

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
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
        objectId: reference(demoFuncRes.id, '2021-03-01', 'Full').identity.principalId
        permissions: keyVaultAppPermissions
      }
    ]
  }
}

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes .id, '2019-06-01').keys[0].value}'
  }
}

resource appServicePlanRes 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: resourceLocation
  sku: appServicePlanSku
  properties: {}
}

resource demoFuncRes 'Microsoft.Web/sites@2021-03-01' = {
  name: demoFuncName
  location: resourceLocation
  kind: 'functionapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${demoFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${demoFuncName}.scm.azurewebsites.net'
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
      ftpsState: 'Disabled'
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      apiDefinition: {
        url: 'https://${demoFuncName}.azurewebsites.net/api/openapi/v3.json'
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource demoFuncAppSettingsRes 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: demoFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes .id, '2019-06-01').keys[0].value}'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsRes.properties.ConnectionString
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_RUN_FROM_PACKAGE: '${storageAccountBlobUri}${blobContainerDeployment}${demoFuncPackagePath}?${listAccountSas(storageAccountRes .id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    WEBSITE_CONTENTSHARE: demoFuncName    
    StorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${keyVaultSecretStorageAccountConnectionString})'
  }  
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
  ]
}

module apiManagementRes './modules.apiManagement.bicep' =  {
  name: 'apim-api-management'
  scope: resourceGroup()
  params: {
    resourceLocation: resourceLocation
    apiMgmtName: apiMgmtName
    apiMgmtSku: apiMgmtSku
    apiMgmtPublisherEmail: apiMgmtPublisherEmail
    apiMgmtPublisherName: apiMgmtPublisherName
    apiMgmtGatewayCustomDomain: apiMgmtGatewayCustomDomain
    appInsightsResId: appInsightsRes.id
    logAnalyticsWsId: logAnalyticsWsRes.id
  }
}
