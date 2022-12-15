@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param logicAppResId string
param actionGroupResId string

param alertOnEveryFailure bool = false
param enableAlertRules bool = true

var alertRuleRunFailurePercentageName = '${resourceNamePrefix}-lafailpct-ar-${resourceNameSuffix}'
var alertRuleRunFailedExecutionsName = '${resourceNamePrefix}-lafails-ar-${resourceNameSuffix}'

// General note 1: Currently metrics can only gathered for a specific resource, not for all Logic Apps in a Resource Group or Subscription. If you
//                 need to create a general monitoring (i.e. not resource specific), you need to enable logging to Log Analytics Workspace
//                 (via Diagnostic Settings) and create a query-based alert.
// General note 2: There are metrics for Triggers, Actions and Runs. Important: If a Trigger fails, no Run will be created (so you need to monitor both)
// More: https://learn.microsoft.com/en-us/azure/logic-apps/monitor-logic-apps-log-analytics


resource alertRuleRunFailurePercentageRes 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(logicAppResId) && !alertOnEveryFailure) {
  name: alertRuleRunFailurePercentageName
  location: 'global'
  properties: {
    severity: 3
    enabled: enableAlertRules
    scopes: [
      logicAppResId
    ]
    targetResourceType: 'Microsoft.Logic/workflows'
    evaluationFrequency: 'PT30M'
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          name: 'FailureRate' // Required name to identify criteria - can have any value
          metricNamespace: 'Microsoft.Logic/workflows'
          metricName: 'RunFailurePercentage'
          operator: 'GreaterThan'
          threshold: 50
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true // Auto-resolve (default = true)
    actions: [
      {
        actionGroupId: actionGroupResId
        webHookProperties: {
        }
      }
    ]
  }
}

resource alertRuleRunFailedExecutionsRes 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(logicAppResId) && alertOnEveryFailure) {
  name: alertRuleRunFailedExecutionsName
  location: 'global'
  properties: {
    severity: 1
    enabled: enableAlertRules
    scopes: [
      logicAppResId
    ]
    targetResourceType: 'Microsoft.Logic/workflows'
    evaluationFrequency: 'PT1H'
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          name: 'Triggers' // Required name to identify criteria - can have any value
          metricNamespace: 'Microsoft.Logic/workflows'
          metricName: 'TriggersFailed'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
        {
          name: 'Runs' // Required name to identify criteria - can have any value
          metricNamespace: 'Microsoft.Logic/workflows'
          metricName: 'RunsFailed'
          operator: 'GreaterThan'
          threshold: 0
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
