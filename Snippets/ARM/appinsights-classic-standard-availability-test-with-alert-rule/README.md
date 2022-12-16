# Application Insights Custom (URL Ping) or Standard Availability Test

Application Insights has a built-in job runner that calls configured endpoints periodically (at either 5-, 10- or 15-minute intervals) from multiple locations and determines their availability as measured by response status and duration.

> More Information: https://learn.microsoft.com/en-us/azure/azure-monitor/app/availability-overview

## Best Practises
* Define an Availability Test along with its Alert Rule for each relevant API endpoint resource (e.g. App Service or Container App), at the outermost level (i.e. including the whole propagation path (e.g. API Management, Front Door))
* Consider providing a dedicated API method for monitoring (e.g. `/api/status`) and implement a connectivity check to all dependencies (e.g. database, bus, storage, ...) there. Include only dependencies which are included in you SLA (external systems may be not)

## Usage

This Bicep module can directly integrated into the deployment like:
```ts
param apiMgmtResName string
param apiMgmtSubscriptionMonitoring string

module availabilityTestApimTestRes './modules.appInsightsAvailabilityTest.bicep' = if(!empty(appInsightsResId) && !empty(apiManagementResName) && !empty(availabilityTestApiMgmtSubscription)) {
  name: 'availability-test-apim-test'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceLocation: resourceLocation
    appInsightsResId: appInsightsResId
    actionGroupResId: actionGrpOrgOpsIssuesResId // Can be empty if createAlertRuleForTest = false
    availabilityTestDisplayName: 'Test API'
    availabilityTestShortName: 'test'
    availabilityTestUrl: 'https://${apiMgmtResName}.azure-api.net/test-api/status?subscription-key=${apiMgmtSubscriptionMonitoring}'
    availabilityTestTypeStandard: true
    createAlertRuleForTest: true
    enableAlertRules: enableAlertRules
  }
}
```

> This is fully compatible with a general [Alerting Strategy](../../../Templates/Guideline-AlertingStrategy) and can be appended to an [alerting module that deploys all Alert Rules of an application](../alert-rules-standard-monitoring-aspects)

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Falert-rule-tampering%2Fmodules.alertRulesTampering.bicep)

## Further Notes

* Can be used as a "keep-alive" function for Function Apps in Consumption Plan
* The generation of an SLA Report is possible, you need to consider the data-retention of Application Insights (default = 90 days). If you need to generate the report for a longer time range, you need to adjust this or export the data to another reporting mechanism.
* [MSDN Inputs to automate this SLA Report (Function with Timer Trigger or Logic App with KQL Query](https://learn.microsoft.com/en-us/azure/azure-monitor/app/automate-custom-reports)
* [MSDN Pricing Details](https://azure.microsoft.com/en-us/pricing/details/monitor/#:~:text=10%5E9%20bytes.-,Web%20Tests,-Application%20Insights%20has)