@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param demoApiSpecInfoJson string = ''

var demoApiRoute = 'demo'
var demoFuncName = '${resourceNamePrefix}-demo-f-${resourceNameSuffix}'
var demoApiSpecInfoObject = json(demoApiSpecInfoJson)

var apiMgmtName = '${resourceNamePrefix}-apim-${resourceNameSuffix}'

resource demoFuncRes 'Microsoft.Web/sites@2021-03-01' existing = {
  name: demoFuncName
}

module apiDefinitionProducerRes './modules.apiDefinition.bicep' = if(!empty(demoApiSpecInfoJson)) {
  name: 'apim-api-definition-${demoApiRoute}'
  scope: resourceGroup()
  params: {
    apiMgmtName: apiMgmtName
    apiMgmtFuncKeySecret: listkeys('${demoFuncRes.id}/host/default', '2021-03-01').functionKeys.default
    apiMgmtApiRoute: demoApiRoute
    apiMgmtApiSubscriptionRequired: true
    apiDefVersion: demoApiSpecInfoObject.version
    apiDefTitle: demoApiSpecInfoObject.title
    apiDefDescription: demoApiSpecInfoObject.description
    apiFuncId: demoFuncRes.id
    apiFuncName: demoFuncName
    apiSpecificationUrl: 'https://${demoFuncName}.azurewebsites.net/api/openapi/v3.json'
  }
}
