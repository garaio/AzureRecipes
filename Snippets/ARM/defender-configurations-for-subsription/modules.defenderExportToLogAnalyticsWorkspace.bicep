param logAnalyticsWsName string

param resourceLocation string = resourceGroup().location

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

resource logAnalyticsSolRes 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityCenterFree(${logAnalyticsWsName})'
  plan: {
    name: 'SecurityCenterFree(${logAnalyticsWsName})'
    product: 'OMSGallery/SecurityCenterFree' // According to Microsoft documentation this still seems to be current and not updated after renaming to Defender (https://learn.microsoft.com/en-us/cli/azure/monitor/log-analytics/solution?view=azure-cli-latest#az-monitor-log-analytics-solution-create-examples)
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWsRes.id
  }
}

resource exportConfigurationRes 'Microsoft.Security/automations@2019-01-01-preview' = {
  name: 'ExportToWorkspace'
  properties: {
    isEnabled: true
    scopes: [
      {
        scopePath: subscription().id
      }
    ]
    sources: [
      {
        eventSource: 'Assessments'
        ruleSets: [
          {
            rules: [
              {
                propertyJPath: 'type'
                propertyType: 'String'
                expectedValue: 'Microsoft.Security/assessments'
                operator: 'Contains'
              }
            ]
          }
        ]
      }
      {
        eventSource: 'Alerts'
        ruleSets: [
          {
            rules: [
              {
                propertyJPath: 'Severity'
                propertyType: 'String'
                expectedValue: 'low'
                operator: 'Equals'
              }
            ]
          }
          {
            rules: [
              {
                propertyJPath: 'Severity'
                propertyType: 'String'
                expectedValue: 'medium'
                operator: 'Equals'
              }
            ]
          }
          {
            rules: [
              {
                propertyJPath: 'Severity'
                propertyType: 'String'
                expectedValue: 'high'
                operator: 'Equals'
              }
            ]
          }
          {
            rules: [
              {
                propertyJPath: 'Severity'
                propertyType: 'String'
                expectedValue: 'informational'
                operator: 'Equals'
              }
            ]
          }
        ]
      }
      {
        eventSource: 'SecureScores'
      }
      {
        eventSource: 'SecureScoresSnapshot'
      }
      {
        eventSource: 'SecureScoreControls'
      }
      {
        eventSource: 'SecureScoreControlsSnapshot'
      }
    ]
    actions: [
      {
        workspaceResourceId: logAnalyticsWsRes.id
        actionType: 'Workspace'
      }
    ]
  }
}

output logAnalyticsWsResId string = logAnalyticsWsRes.id
