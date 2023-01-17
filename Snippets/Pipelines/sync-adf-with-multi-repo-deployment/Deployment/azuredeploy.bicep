@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param isAdfDevelopmentStage bool = false

param adfRepoName string = 'Demo Project ADF'
param adfRepoDevOpsProjectName string = 'Demo Project'
param adfRepoDevOpsOrgName string = 'garaio-customer'

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

var blobContainerDeployment = 'deployment'
var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')

var storageAccountBlobSasParams = {
  signedServices: 'b'
  signedResourceTypes: 'o'
  signedPermission: 'r'
  signedExpiry: '2050-01-01T00:00:00Z'
}
var storageAccountBlobUri = 'https://${storageAccountName}.blob.${environment().suffixes.storage}/'

var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultAppPermissions = {
  keys: [
    'get'
  ]
  secrets: [
    'get'
    'list'
  ]
}

var dataFactoryName = '${resourceNamePrefix}-df-${resourceNameSuffix}'
var dataFactoryContentsDefinitionUri = '${storageAccountBlobUri}${blobContainerDeployment}/Swisseldex.AUM.Deployment/DataFactoryDefinitions/ARMTemplateForFactory.json'

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource storageAccountRes 'Microsoft.Storage/storageAccounts@2021-06-01' = {
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
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
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

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(dataFactoryRes.id, '2018-06-01', 'Full').identity.principalId
        permissions: keyVaultAppPermissions
      }
    ]
  }
}

resource dataFactoryRes 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: resourceLocation
  properties: {
    repoConfiguration: !isAdfDevelopmentStage ? null : {
      type: 'FactoryVSTSConfiguration'
      accountName: adfRepoDevOpsOrgName
      projectName: adfRepoDevOpsProjectName
      repositoryName: adfRepoName
      collaborationBranch: 'develop'
      rootFolder: '/'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataFactoryDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: dataFactoryRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
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

resource dataFactoryContentsRes 'Microsoft.Resources/deployments@2021-01-01' = if (!isAdfDevelopmentStage) {
  name: 'DataFactoryContents'
  properties: {
    mode: 'Incremental'
    templateLink: {
      uri: '${dataFactoryContentsDefinitionUri}?${listAccountSas(storageAccountRes.id, '2021-06-01', storageAccountBlobSasParams).accountSasToken}'
    }
    parameters: {
      factoryName: { 
        value: dataFactoryName
      }
      AzureKeyVault_properties_typeProperties_baseUrl:  { 
        value: 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/'
      }
      // Extend with additional custom parameters
    }
  }
}
