@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param sqlDatabaseResId string
param actionGroupResId string

@description('Average DTU percentage in windows of 5 minutes that leads to raising of alert')
param alertAvgPercentage5MinWindow int = 60

param enableAlertRules bool = true

var alertRuleDtuPercentageName = '${resourceNamePrefix}-sqldtupct-ar-${resourceNameSuffix}'

resource alertRuleDtuPercentageRes 'microsoft.insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(sqlDatabaseResId)) {
  name: alertRuleDtuPercentageName
  location: 'global'
  properties: {
    description: 'Monitors the used DTU capacity and reports when scaling should be considered to avoid outages or performance degradation for customers. See https://learn.microsoft.com/en-us/azure/azure-sql/database/monitoring-sql-database-azure-monitor?view=azuresql#alerts'
    severity: 3
    enabled: enableAlertRules
    scopes: [
      sqlDatabaseResId
    ]
    targetResourceType: 'Microsoft.Sql/servers/databases'
    evaluationFrequency: 'PT5M' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H]
    windowSize: 'PT5M' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, P1D]
    criteria: {
      allOf: [
        {
          threshold: alertAvgPercentage5MinWindow
          name: 'DtuPercentage' // Required name to identify criteria - can have any value
          metricNamespace: 'Microsoft.Sql/servers/databases'
          metricName: 'dtu_consumption_percent'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
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
