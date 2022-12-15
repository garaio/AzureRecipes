@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param cosmosDbAccountResId string
param actionGroupResId string

@description('Average RU percentage in windows of 5 minutes that leads to raising of alert')
param alertAvgPercentage5MinWindow int = 60

param enableAlertRules bool = true

var alertRuleRuPercentageName = '${resourceNamePrefix}-cdbrupct-ar-${resourceNameSuffix}'

resource alertRuleRuPercentageRes 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(cosmosDbAccountResId)) {
  name: alertRuleRuPercentageName
  location: 'global'
  properties: {
    description: 'Monitors the used RU capacity and reports when scaling should be considered to avoid outages or performance degradation for customers. See https://learn.microsoft.com/en-us/azure/cosmos-db/monitor-normalized-request-units'
    severity: 3
    enabled: enableAlertRules
    scopes: [
      cosmosDbAccountResId
    ]
    targetResourceType: 'Microsoft.DocumentDB/databaseAccounts'
    evaluationFrequency: 'PT5M' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H]
    windowSize: 'PT5M' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, P1D]
    criteria: {
      allOf: [
        {
          threshold: alertAvgPercentage5MinWindow
          name: 'RuPercentage'
          metricNamespace: 'Microsoft.DocumentDB/databaseaccounts'
          metricName: 'NormalizedRUConsumption'
          operator: 'GreaterThan'
          timeAggregation: 'Maximum'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true // Auto-resolve
    actions: [
      {
        actionGroupId: actionGroupResId
        webHookProperties: {
        }
      }
    ]
  }
}
