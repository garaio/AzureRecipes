@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param subscriptionId string = subscription().id
param resourceGroupName string = resourceGroup().name

param actionGroupResId string

param enableAlertRules bool = true

var resourceHealthAlertRuleName = '${resourceNamePrefix}-reshealth-ar-${resourceNameSuffix}'

resource resourceHealthAlertRuleRes 'Microsoft.Insights/activityLogAlerts@2020-10-01' = if (!empty(actionGroupResId)) {
  name: resourceHealthAlertRuleName
  location: 'Global'
  properties: {
    scopes: [
      subscriptionId
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ResourceHealth'
        }
        {
          anyOf: [
            {
              field: 'properties.currentHealthStatus'
              equals: 'Degraded'
            }
            {
              field: 'properties.currentHealthStatus'
              equals: 'Unavailable'
            }
          ]
        }
        {
          anyOf: [
            {
              field: 'status'
              equals: 'In Progress'
            }
            {
              field: 'status'
              equals: 'Resolved'
            }
            {
              field: 'status'
              equals: 'Active'
            }
          ]
        }
        {
          anyOf: [
            {
              field: 'properties.previousHealthStatus'
              equals: 'Available'
            }
            {
              field: 'properties.previousHealthStatus'
              equals: 'Unknown'
            }
          ]
        }
        {
          anyOf: [
            {
              field: 'resourceGroup'
              equals: resourceGroupName
            }
          ]
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroupResId
          webhookProperties: {
          }
        }
      ]
    }
    enabled: enableAlertRules
    description: 'Informs that specific resources are impacted by service health issues'
  }
}
