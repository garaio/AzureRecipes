@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param dataFactoryResId string
param actionGroupResId string

param enableAlertRules bool = true

var alertRuleFailedPipelineRunsName = '${resourceNamePrefix}-dfpfails-ar-${resourceNameSuffix}'

resource alertRuleFailedPipelineRunsRes 'Microsoft.Insights/metricalerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(dataFactoryResId)) {
  name: alertRuleFailedPipelineRunsName
  location: 'global'
  properties: {
    description: 'Informs about failed pipeline executions. See https://learn.microsoft.com/en-us/azure/data-factory/monitor-metrics-alerts'
    severity: 1
    enabled: enableAlertRules
    scopes: [
      dataFactoryResId
    ]
    targetResourceType: 'Microsoft.DataFactory/factories'
    evaluationFrequency: 'PT1H' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H]
    windowSize: 'PT1H' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, P1D]
    criteria: {
      allOf: [
        {
          threshold: 0
          name: 'FailedRuns' // Required name to identify criteria - can have any value
          metricNamespace: 'Microsoft.DataFactory/factories'
          metricName: 'PipelineFailedRuns'
          dimensions: [
            {
              name: 'Name'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: false // Auto-resolve (default = true)
    actions: [
      {
        actionGroupId: actionGroupResId
        webHookProperties: {
        }
      }
    ]
  }
}
