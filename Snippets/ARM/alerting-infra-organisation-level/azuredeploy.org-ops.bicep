@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param alertNotificationFallbackEmail string = ''

var actionGrpOpsIndicationsName = '${resourceNamePrefix}-indications-ag-${resourceNameSuffix}'
var actionGrpOpsIndicationsShortName = 'OpsIndic'

var actionGrpOpsIssuesName = '${resourceNamePrefix}-issues-ag-${resourceNameSuffix}'
var actionGrpOpsIssuesShortName = 'OpsIssues'

resource actionGrpOpsIndicationsRes 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGrpOpsIndicationsName
  location: 'Global'
  properties: {
    groupShortName: actionGrpOpsIndicationsShortName // Caution: maximal 12 characters
    enabled: true
    emailReceivers: !empty(alertNotificationFallbackEmail) ? [
      {
        name: 'Fallback'
        emailAddress: alertNotificationFallbackEmail
        useCommonAlertSchema: true
      }
    ] : []
    smsReceivers: []
    webhookReceivers: []
    azureAppPushReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: [
      // Overview of built-in roles with its IDs: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
      {
          name: 'Monitoring Contributor'
          roleId: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
          useCommonAlertSchema: true
      }
    ]
  }
}

resource actionGrpOpsIssuesRes 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGrpOpsIssuesName
  location: 'Global'
  properties: {
    groupShortName: actionGrpOpsIssuesShortName // Caution: maximal 12 characters
    enabled: true
    emailReceivers: !empty(alertNotificationFallbackEmail) ? [
      {
        name: 'Fallback'
        emailAddress: alertNotificationFallbackEmail
        useCommonAlertSchema: true
      }
    ] : []
    smsReceivers: []
    webhookReceivers: []
    azureAppPushReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: [
      // Overview of built-in roles with its IDs: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
      {
          name: 'Monitoring Contributor'
          roleId: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
          useCommonAlertSchema: true
      }
      {
          name: 'Monitoring Reader'
          roleId: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
          useCommonAlertSchema: true
      }
    ]
  }
}

output actionGrpOrgOpsIndicationsResId string = actionGrpOpsIndicationsRes.id
output actionGrpOrgOpsIssuesResId string = actionGrpOpsIssuesRes.id
