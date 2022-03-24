param keyVaultName string
param principalId string
param appPermissions object = {
  keys: [
    'get'
  ]
  secrets: [
    'get'
  ]
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2021-10-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalId
        permissions: appPermissions
      }
    ]
  }
}
