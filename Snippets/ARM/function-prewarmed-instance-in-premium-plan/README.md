# Premium Plan with prewarmed instance(s)

The setup of always running functions with Premium plans consists of two steps:
* App Service Plan with configuration of scale-up setting (SKU: EP1-3) and scale-out settings (minimum/maximum instances used for all assigned Function Apps)
* Function App with site-config properties for scale-out

**Note #1**: There are two similar-looking properties `minimumElasticInstanceCount` (= always ready instances) and `preWarmedInstanceCount` (= pre-warmed instances) - see [according explanation on MSDN](https://docs.microsoft.com/en-us/azure/azure-functions/functions-premium-plan#always-ready-instances).

**Note #2**: You can achieve a similar availability behaviour by using a dedicated App Service plan as used for regular Web Apps and then set the property `alwaysOn` to true. See [this documentation](https://docs.microsoft.com/en-us/azure/azure-functions/functions-scale#always-on) for more details. With that approach you're losing the "serverless" manner and need to define scaling by your own.

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Ffunction-prewarmed-instance-in-premium-plan%2Fazuredeploy.bicep)

# Alternative to be considered

Often the decision for premium plan instead of the regular consumption plan is just because of the cold start behaviour. The cost impact is considerable, not only is the "Free Grant" (1 million requests per month) lost, the always on behaviour also generates minimal costs of ~ 130 CHF/month. Details to pricing of Function Apps see here: https://azure.microsoft.com/en-us/pricing/details/functions
A great and simple alternate may be to deploy an Application Insights Availability Test which calls the Function every 5 minutes and may with that keep it alive and responsive (without consuming too much resources).

> Snippet: [appinsights-classic-standard-availability-test-with-alert-rule](../appinsights-classic-standard-availability-test-with-alert-rule)

Or "quick & dirty" snippet for a classing PING test (without costs):

```ts
var availabilityTestDisplayName = 'Status API'
var availabilityTestShortName = 'status'
var availabilityTestName = '${resourceNamePrefix}-${toLower(availabilityTestShortName)}-at-${resourceNameSuffix}'
var availabilityTestUrl = uri('https://${apiFuncName}.azurewebsites.net', 'api/status')
var availabilityTestFrequencySeconds = 300
var availabilityTestTimeoutSeconds = 120

resource availabilityTestRes 'microsoft.insights/webtests@2022-06-15' = {
  name: availabilityTestName
  location: resourceLocation
  tags: {
    'hidden-link:${appInsightsRes.id}': 'Resource'
  }
  properties: {
    SyntheticMonitorId: availabilityTestName
    Name: availabilityTestDisplayName
    Enabled: true
    Frequency: availabilityTestFrequencySeconds
    Timeout: availabilityTestTimeoutSeconds
    Kind: 'ping'
    RetryEnabled: true
    Locations: [
      {
        Id: 'emea-nl-ams-azr' // West Europe
      }
      {
        Id: 'emea-fr-pra-edge' // France Central
      }
      {
        Id: 'emea-ru-msa-edge' // UK South
      }
      {
        Id: 'emea-gb-db3-azr' // North Europe
      }
      {
        Id: 'emea-ch-zrh-edge' // France South (Formerly France Central)
      }
    ]
    Configuration: {
      WebTest: '<WebTest Name="${availabilityTestDisplayName}" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="${availabilityTestTimeoutSeconds}" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale=""><Items><Request Method="GET" Version="1.1" Url="${availabilityTestUrl}" ThinkTime="0" Timeout="${availabilityTestTimeoutSeconds}" ParseDependentRequests="False" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /></Items></WebTest>'
    }
  }
}
```
