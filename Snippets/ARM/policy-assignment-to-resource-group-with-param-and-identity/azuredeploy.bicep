param resourceLocation string = resourceGroup().location

var policyAssignmentsForTags = [
  'DeployedAt'
  'DeployedBy'
  'DeployedFrom'
]

// See sample: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#tenantresourceid
resource policyAssignmentRes 'Microsoft.Authorization/policyAssignments@2019-09-01' = [for item in policyAssignmentsForTags: {
  name: 'Inherit Tag: ${item}'
  properties: {
    scope: subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroup().name)
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'ea3f2387-9b95-492a-a190-fcdc54f7b070')
    parameters: {
      tagName: {
        value: item
      }
    }
  }
  location: resourceLocation
  identity: {
    type: 'SystemAssigned'
  }
}]
