@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param apiManagementResId string
param actionGroupResId string

@description('Average capacity used over 1 hour, indicating that scaling may be needed')
param alertAvgCapacity1HourWindow int = 50

param enableAlertRules bool = true

var alertRuleApimCapacityName = '${resourceNamePrefix}-apimcap-ar-${resourceNameSuffix}'

resource alertRuleApimCapacityRes 'Microsoft.Insights/metricAlerts@2018-03-01' = if (!empty(actionGroupResId) && !empty(apiManagementResId)) {
  name: alertRuleApimCapacityName
  location: 'global'
  properties: {
    description: 'Monitors the used capacity of the API management instance and reports when scaling should be considered to avoid outages or performance degradation for customers. See https://learn.microsoft.com/en-gb/azure/api-management/api-management-capacity'
    severity: 3
    enabled: enableAlertRules
    scopes: [
      apiManagementResId
    ]
    targetResourceType: 'Microsoft.ApiManagement/service'
    evaluationFrequency: 'PT1H'
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          threshold: alertAvgCapacity1HourWindow
          name: 'Capacity' // Required name to identify criteria - can have any value
          metricNamespace: 'microsoft.apimanagement/service'
          metricName: 'Capacity'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: actionGroupResId
        webHookProperties: {
        }
      }
    ]
  }
}
