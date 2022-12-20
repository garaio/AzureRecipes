# Storage Account Lifecycle Management Rule

Storage Accounts have a great built-in job runner to delete blobs or change theier tier: https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview

```ts
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
```

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Fstorage-account-lifecycle-management-rule%2Fazuredeploy.bicep)