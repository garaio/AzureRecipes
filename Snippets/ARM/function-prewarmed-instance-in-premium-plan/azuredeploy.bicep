@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@description('See https://learn.microsoft.com/en-us/azure/azure-functions/configure-monitoring?tabs=v2#configure-scale-controller-logs')
param enableScaleControllerLogs bool = false

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var templateFuncName = '${resourceNamePrefix}-template-f-${resourceNameSuffix}'

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
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 20
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
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      minimumElasticInstanceCount: 1
      preWarmedInstanceCount: 1
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
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_CONTENTSHARE: templateFuncName
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsRes.properties.ConnectionString
    SCALE_CONTROLLER_LOGGING_ENABLED: 'AppInsights:${enableScaleControllerLogs ? 'Verbose' : 'None'}'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  }
}
