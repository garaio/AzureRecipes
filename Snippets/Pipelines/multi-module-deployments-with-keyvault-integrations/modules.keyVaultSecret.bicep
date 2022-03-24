param keyVaultName string
param secretName string
@secure()
param secretValue string

resource keyVaultRes 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretRes 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyVaultRes
  name: secretName
  properties: {
    value: secretValue
  }
}
