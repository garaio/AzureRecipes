targetScope = 'managementGroup'

@allowed([
  'switzerlandnorth'
  'westeurope'
])
param resourceLocation string = 'switzerlandnorth'

var inheritTagPolicyAssignmentsForTags = [
  'DeployedAt'
  'DeployedBy'
  'DeployedFrom'
]
var requireTagPolicyAssignmentsForTags = [
  'DeployedAt'
  'DeployedBy'
  'DeployedFrom'
]

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

resource inheritTagPolicyAssignmentsForTagsRes 'Microsoft.Authorization/policyAssignments@2020-03-01' = [for item in inheritTagPolicyAssignmentsForTags: {
  name: 'Inherit: ${item}'
  properties: {
    scope: managementGroup().id
    policyDefinitionId: extensionResourceId(tenantResourceId('Microsoft.Management/managementGroups', managementGroup().name), 'Microsoft.Authorization/policyDefinitions', 'ea3f2387-9b95-492a-a190-fcdc54f7b070')
    displayName: 'Inherit tag from Resource Group: ${item}'
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

resource requireTagPolicyAssignmentsForTagsRes 'Microsoft.Authorization/policyAssignments@2020-03-01' = [for (item, i) in requireTagPolicyAssignmentsForTags: {
  name: 'Require: ${item}'
  properties: {
    scope: managementGroup().id
    policyDefinitionId: extensionResourceId(tenantResourceId('Microsoft.Management/managementGroups', managementGroup().name), 'Microsoft.Authorization/policyDefinitions', '96670d01-0a4d-4649-9c89-2d3abc0a5025')
    displayName: 'Require tag on Resource Group: ${inheritTagPolicyAssignmentsForTags[i]}'
    parameters: {
      tagName: {
        value: item
      }
    }
    enforcementMode: 'DoNotEnforce'
  }
}]
