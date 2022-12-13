@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@allowed([
  'Consumption'
  'Developer'
  'Basic'
])
param apiMgmtSku string = 'Developer'
param apiMgmtPublisherEmail string = 'project@customer.com'
param apiMgmtPublisherName string = 'Customer AG'

@secure()
param apiManagementKey string = base64(newGuid())

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var templateFuncName = '${resourceNamePrefix}-template-f-${resourceNameSuffix}'
var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}

var apiMgmtName = '${resourceNamePrefix}-apim-${resourceNameSuffix}'

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

resource appServicePlanRes 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: resourceLocation
  sku: appServicePlanSku
  properties: {}
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

resource templateFuncRes 'Microsoft.Web/sites@2021-03-01' = {
  kind: 'functionapp'
  name: templateFuncName
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
      ftpsState: 'Disabled'
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

resource templateFuncAppSettingsRes 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: templateFuncRes
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsRes.properties.InstrumentationKey
    APPINSIGHTS_PROFILERFEATURE_VERSION: '1.0.0'
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION: '1.0.0'
    DiagnosticServices_EXTENSION_VERSION: '~3'
    ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTSHARE: templateFuncName
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
  }
}

// Note: Not officially documented - it could be more stable to deploy it via CLI command in pipeline
#disable-next-line BCP081
resource templateFuncHostKeyApimRes 'Microsoft.Web/sites/host/functionKeys@2019-08-01' = {
  name: '${templateFuncName}/default/apimanagement'
  properties: {
    name: 'apimanagement'
    value: apiManagementKey
  }
  dependsOn: [
    templateFuncRes
  ]
}

module apiManagementRes './modules.apiManagement.bicep' =  {
  name: 'apim-api-definitions'
  scope: resourceGroup()
  params: {
    resourceLocation: resourceLocation
    apiMgmtName: apiMgmtName
    apiMgmtSku: apiMgmtSku
    apiMgmtPublisherEmail: apiMgmtPublisherEmail
    apiMgmtPublisherName: apiMgmtPublisherName
    apiMgmtFuncKeySecret: apiManagementKey
    templateFuncId: templateFuncRes.id
    templateFuncName: templateFuncName
    appInsightsId: appInsightsRes.id
    appInsightsName: appInsightsName
    logAnalyticsWsId: logAnalyticsWsRes.id
    monitoringSubscriptionKey: ''
  }
  dependsOn: [
    templateFuncAppSettingsRes
  ]
}
