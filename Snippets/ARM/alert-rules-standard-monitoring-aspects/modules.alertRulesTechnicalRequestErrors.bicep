@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param appInsightsResId string
param actionGroupResId string

@description('Threshold to fire alert (if errors > x per hour)')
param alertTreshold1HourWindow int = 0

param enableAlertRules bool = true

var alertRuleTechReqErrorsName = '${resourceNamePrefix}-techreqerr-ar-${resourceNameSuffix}'

resource alertRuleTechReqErrorsRes 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(appInsightsResId)) {
  name: alertRuleTechReqErrorsName
  location: 'global'
  properties: {
    description: 'Unhandled internal server errors in any Function'
    severity: 1
    enabled: enableAlertRules
    scopes: [
      appInsightsResId
    ]
    evaluationFrequency: 'PT1H'
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          threshold: alertTreshold1HourWindow
          name: 'Failures'
          metricNamespace: 'Microsoft.Insights/components'
          metricName: 'requests/failed'
          dimensions: [
            {
              name: 'request/resultCode'
              operator: 'Include'
              values: [
                '500'
                '501'
                '503'
                '505'
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
    autoMitigate: true
    targetResourceType: 'Microsoft.Insights/components'
    targetResourceRegion: resourceLocation
    actions: [
      {
        actionGroupId: actionGroupResId
        webHookProperties: {}
      }
    ]
  }
}
