@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param appInsightsResId string
param actionGroupResId string

@description('Average DTU percentage in windows of 5 minutes that leads to raising of alert')
param alertPercentage6HourWindow int = 5

param enableAlertRules bool = true

var alertRuleRequestFailurePercentageName = '${resourceNamePrefix}-reqfailpct-ar-${resourceNameSuffix}'

resource alertRuleRequestFailurePercentageRes 'Microsoft.Insights/scheduledqueryrules@2022-06-15' = if (!empty(actionGroupResId) && !empty(appInsightsResId)) {
  name: alertRuleRequestFailurePercentageName
  location: resourceLocation
  properties: {
    description: 'Calculates and monitors failure rate (in percent) for requests of connected App Services (incl. Function Apps) and API Management instances'
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
          query: 'requests \n| project timestamp, name, success, resultCode, cloud_RoleName, operation_Id\n| summarize\n    failurePercentage = todouble(countif(success == false)) / count(),\n    make_set_if(resultCode, success == false)\n    by cloud_RoleName\n| extend cloud_RoleName=tostring(split(cloud_RoleName, \' \')[0])\n'
          timeAggregation: 'Maximum'
          metricMeasureColumn: 'failurePercentage'
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
          threshold: alertPercentage6HourWindow
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
