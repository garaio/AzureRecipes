@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param serviceBusResId string
param actionGroupResId string

param enableAlertRules bool = true

var alertRuleDeadLetterQueueingName = '${resourceNamePrefix}-sbdlq-ar-${resourceNameSuffix}'

resource alertRuleDeadLetterQueueingRes 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(serviceBusResId)) {
  name: alertRuleDeadLetterQueueingName
  location: 'global'
  properties: {
    description: 'Monitors dead-letter queues and informs when a new message is appended (final cancelled and sorted out). See https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues'
    severity: 2
    enabled: enableAlertRules
    scopes: [
      serviceBusResId
    ]
    targetResourceType: 'Microsoft.ServiceBus/namespaces'
    evaluationFrequency: 'PT1H' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H]
    windowSize: 'PT1H' // Must be one of [PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, P1D]
    criteria: {
      allOf: [
        {
          threshold: 0
          name: 'DeadLetterQueueing' // Required name to identify criteria - can have any value
          metricNamespace: 'Microsoft.ServiceBus/namespaces'
          metricName: 'AbandonMessage'
          dimensions: [
            {
              name: 'EntityName'
              operator: 'Include'
              values: [
                'triggers'
              ]
            }
          ]
          operator: 'GreaterThan'
          timeAggregation: 'Count'
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
