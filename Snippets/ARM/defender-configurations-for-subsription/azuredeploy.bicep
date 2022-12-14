targetScope = 'subscription'

@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

@allowed([
  'Free'
  'Standard'
])
param defenderPlan string = 'Free'

@description('Email addresses (separated with semicolons) to send notifications concerning security alerts')
param securityContactsEmails string

@description('Location of the Log Analytics Workspace used to store exported Defender for Cloud data')
@allowed([
  'switzerlandnorth'
  'westeurope'
])
param resourceLocation string = 'switzerlandnorth'

var resourceGroupName = '${resourceNamePrefix}-${resourceNameSuffix}'
var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

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

resource defenderPlanRes 'Microsoft.Security/pricings@2022-03-01' = {
  name: 'default'
  properties: {
    pricingTier: defenderPlan
  }
}

resource securityContactRes 'Microsoft.Security/securityContacts@2020-01-01-preview' = {
  name: 'default'
  properties: {
    alertNotifications: {
      minimalSeverity: 'Medium'
      state: 'On'
    }
    emails: securityContactsEmails
    notificationsByRole: {
      roles: [
        'Owner'
      ]
      state: 'On'
    }
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceLocation
  properties: {}
}

module exportTologAnalyticsWorkspaceRes './modules.defenderExportToLogAnalyticsWorkspace.bicep' = {
  name: '${deployment().name}-law'
  scope: resourceGroup
  params: {
    logAnalyticsWsName: logAnalyticsWsName
    resourceLocation: resourceLocation
  }
}
