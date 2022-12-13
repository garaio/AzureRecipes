@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param monitoringAlertsReceiverEmail string = 'no-reply@garaio.com'

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var actionGrpAdminName = '${resourceNamePrefix}-admin-ag-${resourceNameSuffix}'
var alertRuleTamperingName = '${resourceNamePrefix}-tampering-ar-${resourceNameSuffix}'

resource partnerIdRes 'Microsoft.Resources/deployments@2020-06-01' = {
  name: 'pid-d16e7b59-716a-407d-96db-18d1cac40407'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
  }
}

resource actionGrpAdminRes 'Microsoft.Insights/actionGroups@2019-03-01' = {
  name: actionGrpAdminName
  location: 'Global'
  properties: {
    groupShortName: 'Admin'
    enabled: true
    emailReceivers: [
      {
        name: 'ResponsibleEmail'
        emailAddress: monitoringAlertsReceiverEmail
        useCommonAlertSchema: false
      }
    ]
    smsReceivers: []
  }
}

resource alertRuleTamperingRes 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: alertRuleTamperingName
  location: resourceLocation
  properties: {
    description: 'Manual activities in PROD environment'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT30M'
    scopes: [
      logAnalyticsWsRes.id
    ]
    windowSize: 'PT45M'
    criteria: {
      allOf: [
        {
          query: 'let ignored = dynamic(["listKeys", "listAdminKeys", "listQueryKeys", "querydebugpipelineruns", "pipelines/createRun", "triggers/start", "triggers/getEventSubscriptionStatus", "service/subscriptions", "service/users/token/action", "workspaces/metadata/action", "deployments/exportTemplate"]);\nlet resourceGroupName = "${resourceGroup().name}";\nAzureActivity \n| where ResourceGroup =~ resourceGroupName\n| where CategoryValue == "Administrative"\n| where ActivityStatusValue =~ "Started"\n| where isnotempty(Caller) and isnull(toguid(Caller))\n| where not(OperationNameValue has_any(ignored))\n| order by TimeGenerated desc\n| project TimeGenerated, Caller, CallerIpAddress, OperationNameValue, ResourceProviderValue, OperationName\n'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    muteActionsDuration: 'PT2H'
    autoMitigate: false // Auto-resolve - not supported in combination with suppression (muteActionsDuration)
    actions: {
      actionGroups: [
        actionGrpAdminRes.id
      ]
      customProperties: {
        subject: 'Manual Activities in Resource Group ${resourceGroup().name} detected'
      }
    }
  }
}
