@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param appInsightsResId string
param actionGroupResId string

@description('Default timeout in consumption plan is 5 Minutes: https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale#timeout')
param alertDurationInSeconds int = 240

param enableAlertRules bool = true

var alertRuleFuncDurName = '${resourceNamePrefix}-funcdur-ar-${resourceNameSuffix}'

resource alertRuleFuncDurRes 'Microsoft.Insights/scheduledqueryrules@2022-06-15' = if (!empty(actionGroupResId) && !empty(appInsightsResId)) {
  name: alertRuleFuncDurName
  location: resourceLocation
  properties: {
    description: 'Observes maximal execution duration per function app and raises an alert when configured treshold (typically 80% from limit) is reached. See https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale#timeout'
    severity: 3
    enabled: enableAlertRules
    scopes: [
      appInsightsResId
    ]
    targetResourceTypes: [
      'Microsoft.Insights/components'
    ]
    evaluationFrequency: 'PT6H'
    windowSize: 'PT6H'
    criteria: {
      allOf: [
        {
          query: 'customMetrics\n| where name has "MaxDurationMs" and sdkVersion startswith "af:"\n| summarize maxDuration = max(valueSum) / 1000 by cloud_RoleName\n\n'
          timeAggregation: 'Maximum'
          metricMeasureColumn: 'maxDuration'
          dimensions: [
            {
              name: 'cloud_RoleName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThan'
          threshold: alertDurationInSeconds
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    muteActionsDuration: 'P1D'
    actions: {
      actionGroups: [
        actionGroupResId
      ]
    }
  }
}
