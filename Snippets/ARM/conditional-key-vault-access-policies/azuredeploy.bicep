
@description('The prefix will be used for every parameter that represents a resource name.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name.')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param deployDemoFunction bool = true

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

var appServicePlanName = '${resourceNamePrefix}-asp-${resourceNameSuffix}'
var appServicePlanSku = {
  name: 'Y1'
  tier: 'Dynamic'
}

var demoFuncName = '${resourceNamePrefix}-demo-f-${resourceNameSuffix}'

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

resource keyVaultAccessPoliciesRes  'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultRes.name}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: deployDemoFunction ? reference(demoFuncRes.id, '2021-03-01', 'Full').identity.principalId : '00000000-0000-0000-0000-000000000000'
        permissions: deployDemoFunction ? keyVaultAppPermissions : {}
      }
    ]
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
  kind: 'functionapp'
  location: resourceLocation
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
    appInsightsRes
  ]
}
