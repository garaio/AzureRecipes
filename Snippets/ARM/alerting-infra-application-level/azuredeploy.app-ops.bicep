@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param actionGrpOrgOpsIndicationsResId string

param createDevOpsHandler bool = true
param enableAlertRules bool = true

module alertHandlerDevOpsRes './modules.alertHandlerDevOps.bicep' = if (createDevOpsHandler) {
  name: 'alert-handler-devops'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceLocation: resourceLocation
    devOpsOrgName: 'org-name'
    devOpsProjectName: 'project-name'
  }
}

module alertRulesServiceHealthRes './modules.alertRulesServiceHealth.bicep' =  {
  name: 'alert-rules-servicehealth'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    actionGroupResId: actionGrpOrgOpsIndicationsResId
    subscriptionId: subscription().id
    enableAlertRules: enableAlertRules
  }
}

output actionGrpAppDevOpsTeamResId string = createDevOpsHandler ? alertHandlerDevOpsRes.outputs.actionGrpResId : ''
