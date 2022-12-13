param resourceLocation string = resourceGroup().location

param containerRegistryLoginServer string = ''
param containerRegistryUsername string = ''
@secure()
param containerRegistryPassword string = ''

param dockerImageName string = 'azurerecipe'
param dockerImageTag string = ''

resource dockerImage 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: dockerImageName
  location: resourceLocation
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: dockerImageName
        properties: {
          image: '${containerRegistryLoginServer}/${dockerImageName}:${dockerImageTag}'
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          environmentVariables: []
          resources: {
            requests: {
              memoryInGB: json('1.5')
              cpu: 1
            }
          }
        }
      }
    ]
    initContainers: []
    imageRegistryCredentials: [
      {
        server: containerRegistryLoginServer
        username: containerRegistryUsername
        password: containerRegistryPassword
      }
    ]
    restartPolicy: 'OnFailure'
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
      ip: '20.101.5.52'
      type: 'Public'
    }
    osType: 'Linux'
  }
}
