@description('The prefix will be used for every parameter that represents a resource name. See the description of the parameter.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name. See the description of the parameter.')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param keyVaultName string
param keyVaultResourceGroupName string

@allowed([
  'Free_F1'
  'Standard_S1'
])
param signalRServiceSku string = 'Free_F1'

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

var keyVaultSecretSignalRConnectionString = 'signalRConnectionString'

var signalRServiceName = '${resourceNamePrefix}-sigr-${resourceNameSuffix}'

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

resource signalRServiceRes 'Microsoft.SignalRService/signalR@2021-10-01' = {
  name: signalRServiceName
  location: resourceLocation
  sku: {
    name: signalRServiceSku
    capacity: 1
  }
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Serverless'
      }
      {
        flag: 'EnableConnectivityLogs'
        value: 'true'
      }
      {
        flag: 'EnableMessagingLogs'
        value: 'true'
      }
      {
        flag: 'EnableLiveTrace'
        value: 'true'
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    tls: {
      clientCertEnabled: false
    }
  }
}

resource signalRServiceDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: signalRServiceRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'AllLogs'
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

module keyVaultSecretSignalRConnectionStringRes './modules.keyVaultSecret.bicep' = if (!empty(keyVaultName) && !empty(keyVaultResourceGroupName)) {
  name: keyVaultSecretSignalRConnectionString
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    secretName: keyVaultSecretSignalRConnectionString
    secretValue: listKeys(signalRServiceRes.id, '2021-10-01').primaryConnectionString
  }
}
