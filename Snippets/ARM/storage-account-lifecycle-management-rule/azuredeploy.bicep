@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

var blobContainerConfig = 'config'
var blobContainerData = 'data'
var blobContainerBackup = 'backup'

var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var storageAccountBlobs = [
  {
    name: blobContainerConfig
    publicAccess: 'None'
  }
  {
    name: blobContainerData
    publicAccess: 'None'
  }
  {
    name: blobContainerBackup
    publicAccess: 'None'
  }
]

resource storageAccountRes 'Microsoft.Storage/storageAccounts@2022-05-01' = {
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
    allowBlobPublicAccess: true
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

resource storageAccountBlobContainerRes 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [for item in storageAccountBlobs: {
  name: '${storageAccountName}/default/${item.name}'
  properties: {
    publicAccess: item.publicAccess
  }
  dependsOn: [
    storageAccountRes
  ]
}]

// Documentation: https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/managementpolicies
resource storageAccountLifecycleManagementRuleRes 'Microsoft.Storage/storageAccounts/managementPolicies@2022-05-01' = {
  parent: storageAccountRes
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'Change Tier of <data>'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 60
                }
                tierToArchive: {
                  daysAfterLastTierChangeGreaterThan: 7
                  daysAfterModificationGreaterThan: 365
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                '${blobContainerData}/'
                '${blobContainerBackup}/'
              ]
            }
          }
        }
      ]
    }
  }
}
