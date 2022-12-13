param resourceLocation string = resourceGroup().location

resource azurerecipes 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: 'azurerecipes'
  location: resourceLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    networkRuleSet: {
      defaultAction: 'Allow'
    }
  }
}
