@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@allowed([
  'User'
  'Group'
])
param synapseIdentityType string = 'Group'
param synapseIdentityId string = '00000000-0000-0000-0000-000000000000'

@description('Generate logic app resources based on linked templates')
param deployLogicApps bool = false

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'

var blobContainerDeployment = 'deployment'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var storageAccountBlobs = [
  {
    name: blobContainerDeployment
    publicAccess: 'None'
  }
]
var storageAccountFunctionSasParams = {
  signedServices: 'b'
  signedResourceTypes: 'o'
  signedPermission: 'r'
  signedExpiry: '2050-01-01T00:00:00Z'
}
var storageAccountBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/'

var dataLakeStorageName = replace('${resourceNamePrefix}-dls-${resourceNameSuffix}', '-', '')
var dataLakeFilesystemName = 'workspace'

var synapseWorkspaceName = '${resourceNamePrefix}-sw-${resourceNameSuffix}'
var synapseSqlAdminUser = 'sqladminuser'
var synapseBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var synapseResourceGroupName = '${resourceNamePrefix}-synapse-internal-${resourceNameSuffix}'

var logicAppFileIntegrationName = '${resourceNamePrefix}-fi-la-${resourceNameSuffix}'
var logicAppFileIntegrationDefUri = '${storageAccountBlobUri}${blobContainerDeployment}/LogicApps/file-integration.json'

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

resource storageAccountRes 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageAccountBlobContainerRes 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = [for item in storageAccountBlobs: {
  name: '${storageAccountName}/default/${item.name}'
  properties: {
    publicAccess: item.publicAccess
  }
  dependsOn: [
    storageAccountRes
  ]
}]

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    enableSoftDelete: true // With default of softDeleteRetentionInDays = 90
    accessPolicies: []
  }
}

resource keyVaultDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: keyVaultRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource dataLakeStorageRes 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: dataLakeStorageName
  location: resourceLocation
  tags: {
    Type: 'Synapse Data Lake Storage'
  }
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource dataLakeStorageBlobRes 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  name: '${dataLakeStorageRes.name}/default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource dataLakeStorageBlobContainerRes 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${dataLakeStorageBlobRes.name}/${dataLakeFilesystemName}'
  properties: {
    publicAccess: 'None'
  }
}

resource dataLakeStorageRoleAssignmentServiceRes 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('${resourceGroup().id}/${synapseBlobDataContributorRoleID}/${synapseWorkspaceName}')
  scope: dataLakeStorageRes
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', synapseBlobDataContributorRoleID)
    principalId: reference(synapseWorkspaceRes.id, '2021-03-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource dataLakeStorageRoleAssignmentUserRes 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (!empty(synapseIdentityId)) {
  name: guid('${resourceGroup().id}/${synapseBlobDataContributorRoleID}/${synapseIdentityId}')
  scope: dataLakeStorageRes
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', synapseBlobDataContributorRoleID)
    principalId: synapseIdentityId
    principalType: synapseIdentityType
  }
}

resource synapseWorkspaceRes 'Microsoft.Synapse/workspaces@2021-03-01' = {
  name: synapseWorkspaceName
  location: resourceLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${dataLakeStorageName}.dfs.${environment().suffixes.storage}'
      filesystem: dataLakeFilesystemName
    }
    virtualNetworkProfile: {
      computeSubnetId: ''
    }
    sqlAdministratorLogin: synapseSqlAdminUser
    managedResourceGroupName: synapseResourceGroupName
  }
}

resource synapseWorkspaceFirewallRuleRes 'Microsoft.Synapse/workspaces/firewallrules@2021-03-01' = {
  name: '${synapseWorkspaceRes.name}/allowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource synapseWorkspaceSecuritySettingsRes 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-03-01' = {
  name: '${synapseWorkspaceRes.name}/default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: 'Enabled'
    }
  }
}

resource synapseWorkspaceDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: synapseWorkspaceRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'SynapseRbacOperations'
        enabled: true
      }
      {
        category: 'GatewayApiRequests'
        enabled: true
      }
      {
        category: 'BuiltinSqlReqsEnded'
        enabled: true
      }
      {
        category: 'IntegrationPipelineRuns'
        enabled: true
      }
      {
        category: 'IntegrationActivityRuns'
        enabled: true
      }
      {
        category: 'IntegrationTriggerRuns'
        enabled: true
      }
    ]
  }
}

resource logicAppFileIntegrationRes 'Microsoft.Resources/deployments@2021-01-01' = if (deployLogicApps) {
  name: logicAppFileIntegrationName
  properties: {
    mode: 'Incremental'
    templateLink: {
      uri: '${logicAppFileIntegrationDefUri}?${listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountFunctionSasParams).accountSasToken}'
    }
    parameters: {
      LogicAppName:  { 
        value: logicAppFileIntegrationName
      }
    }
  }
}

resource logicAppFileIntegrationDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: logicAppFileIntegrationRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
