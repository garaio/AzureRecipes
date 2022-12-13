targetScope = 'subscription'

@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

var resourceGroupName = '${resourceNamePrefix}-${resourceNameSuffix}'
var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var activityLogDiagSettingsName = '${resourceNamePrefix}-alds-${resourceNameSuffix}'

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: logAnalyticsWsName
  scope: resourceGroup(resourceGroupName)
}

resource activityLogDiagSettingsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: activityLogDiagSettingsName
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Security'
        enabled: true
      }
      {
        category: 'ServiceHealth'
        enabled: true
      }
      {
        category: 'Alert'
        enabled: true
      }
      {
        category: 'Recommendation'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
      {
        category: 'Autoscale'
        enabled: true
      }
      {
        category: 'ResourceHealth'
        enabled: true
      }
    ]
  }
}
