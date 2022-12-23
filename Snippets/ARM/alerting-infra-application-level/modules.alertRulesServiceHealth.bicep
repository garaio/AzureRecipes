@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param subscriptionId string = subscription().id

param actionGroupResId string

param enableAlertRules bool = true

var serviceHealthAlertRuleName = '${resourceNamePrefix}-svchealth-ar-${resourceNameSuffix}'

resource serviceHealthAlertRuleRes 'Microsoft.Insights/activityLogAlerts@2020-10-01' = if (!empty(actionGroupResId)) {
  name: serviceHealthAlertRuleName
  location: 'Global'
  properties: {
    scopes: [
      subscriptionId
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
        {
          anyOf: [
            {
              field: 'properties.incidentType'
              equals: 'Incident'
            }
          ]
        }
        {
          field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
          containsAny: [
            'North Europe'
            'West Europe'
            'Switzerland North'
            'Switzerland West'
            'Global'
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
    description: 'General service health issues related to all resources in the subscriptions (for information)'
  }
}
