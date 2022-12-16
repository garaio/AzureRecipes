@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param appInsightsResId string
@description('Only relevant if "createAlertRuleForTest" is set to true')
param actionGroupResId string = ''

param availabilityTestDisplayName string
@description('Must be unique within Resource Group (used for resource naming)')
param availabilityTestShortName string
param availabilityTestUrl string

@description('Standard tests instead of the (classic) Ping tests provide advanced validation and better response validation, but costs ~ 6 CHF/month (classic ping tests are free)')
param availabilityTestTypeStandard bool = false

param createAlertRuleForTest bool = true
param enableAlertRules bool = true

var availabilityTestName = '${resourceNamePrefix}-${toLower(availabilityTestShortName)}-at-${resourceNameSuffix}'
var availabilityTestFrequencySeconds = 300
var availabilityTestTimeoutSeconds = 120

var alertRuleName = '${resourceNamePrefix}-${toLower(availabilityTestShortName)}-ar-${resourceNameSuffix}'

resource availabilityTestStandardRes 'Microsoft.Insights/webtests@2022-06-15' = if (availabilityTestTypeStandard) {
  name: (availabilityTestTypeStandard ? availabilityTestName : uniqueString(resourceGroup().id))
  location: resourceLocation
  tags: {
    'hidden-link:${appInsightsResId}': 'Resource'
  }
  properties: {
    SyntheticMonitorId: availabilityTestName
    Name: availabilityTestDisplayName
    Enabled: true
    Frequency: availabilityTestFrequencySeconds
    Timeout: availabilityTestTimeoutSeconds
    Kind: 'standard'
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
    Request: {
      RequestUrl: availabilityTestUrl
      HttpVerb: 'GET'
      ParseDependentRequests: false
    }
    ValidationRules: {
      IgnoreHttpsStatusCode: false
      ExpectedHttpStatusCode: 0 // Equals UI-setting "Response code < 400"
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
      // ContentValidation -> Use for advanced checks, see https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/webtests?pivots=deployment-language-bicep#webtestpropertiesvalidationrulescontentvalidation
    }
  }
}

resource availabilityTestPingRes 'Microsoft.Insights/webtests@2022-06-15' = if (!availabilityTestTypeStandard) {
  name: (availabilityTestTypeStandard ? uniqueString(resourceGroup().id) : availabilityTestName)
  location: resourceLocation
  tags: {
    'hidden-link:${appInsightsResId}': 'Resource'
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

resource alertRuleRes 'Microsoft.Insights/metricalerts@2018-03-01' = if (createAlertRuleForTest && !empty(actionGroupResId)) {
  name: alertRuleName
  location: 'global'
  tags: {
    'hidden-link:${appInsightsResId}': 'Resource'
    'hidden-link:${resourceId('Microsoft.Insights/webtests', availabilityTestName)}': 'Resource'
  }
  properties: {
    description: 'Custom availability test \'${availabilityTestDisplayName}\' repeatedly did not show a good result'
    severity: 1
    enabled: enableAlertRules
    scopes: [
      resourceId('Microsoft.Insights/webtests', availabilityTestName)
      appInsightsResId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      webTestId: resourceId('Microsoft.Insights/webtests', availabilityTestName)
      componentId: appInsightsResId
      failedLocationCount: 2
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
    }
    actions: [
      {
        actionGroupId: actionGroupResId
      }      
    ]
  }
  dependsOn: [
    availabilityTestStandardRes
    availabilityTestPingRes
  ]
}
