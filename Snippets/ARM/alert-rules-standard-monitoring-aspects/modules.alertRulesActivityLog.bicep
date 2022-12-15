@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceGroupId string = resourceGroup().id

param actionGroupResId string

param enableAlertRules bool = true

var roleAsgmtAlertRuleName = '${resourceNamePrefix}-rasgmt-ar-${resourceNameSuffix}'

resource roleAsgmtAlertRuleRes 'Microsoft.Insights/activityLogAlerts@2020-10-01' = if (!empty(actionGroupResId)){
  name: roleAsgmtAlertRuleName
  location: 'Global'
  properties: {
    scopes: [
      resourceGroupId
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          field: 'operationName'
          equals: 'Microsoft.Authorization/roleAssignments/write'
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
    description: 'Added new role assignment for a resource in the resource group'
  }
}
