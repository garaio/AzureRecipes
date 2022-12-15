# Alert Rule

# Alert Rule for manual user activities in Resource Group (tampering)
Especially for productive environments it may be valuable to get notified of any manual changes (e.g. to make sure they are properly reflected in documentation or deployment scripts)

This Bicep module can directly integrated into the deployment like:
```ts
module alertRuleTamperingRes './modules.alertRulesTampering.bicep' = {
  name: 'alert-rules-tampering'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceGroupId: resourceGroup().id
    logAnalyticsWsResId: logAnalyticsWsResId
    actionGroupResId: actionGrpOrgOpsIndicationsResId
    enableAlertRules: enableAlertRules
  }
}
```

> This is fully compatible with a general [Alerting Strategy](../../../Templates/Guideline-AlertingStrategy) and can be appended to an [alerting module that deploys all Alert Rules of an application](../alert-rules-standard-monitoring-aspects)

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Falert-rule-tampering%2Fmodules.alertRulesTampering.bicep)