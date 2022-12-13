param deployedAt string = utcNow('yyyy-MM-dd')
param deployedBy string = 'n/a'
param deployedFrom string = 'n/a'

resource tagsOnResourceGroupRes 'Microsoft.Resources/tags@2020-10-01' = {
  name: 'default'
  properties: {
    tags: {
      DeployedAt: deployedAt
      DeployedBy: deployedBy
      DeployedFrom: deployedFrom
    }
  }
}
