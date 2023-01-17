param apiMgmtName string
@secure()
param apiMgmtFuncKeySecret string
param apiMgmtApiRoute string
param apiMgmtApiSubscriptionRequired bool

param apiDefVersion string = '1.0.0'
param apiDefTitle string = ''
param apiDefDescription string = ''

param apiFuncId string
param apiFuncName string
param apiSpecificationUrl string

var apiDefVersionParts = split(apiDefVersion, '.')
var apiVersionHeaderName = 'Api-Version'

var apiMgmtApiName = '${apiFuncName}-v${apiDefVersionParts[0]}' // e.g. 'customer-project-demo-f-t-v1'

resource apiMgmtRes 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiMgmtName
}

resource apiMgmtVersionSetRes 'Microsoft.ApiManagement/service/apiVersionSets@2021-08-01' = {
  name: '${apiFuncName}-versions'
  parent: apiMgmtRes
  properties: {
    displayName: !empty(apiDefTitle) ? apiDefTitle : apiFuncName
    versioningScheme: 'Segment'
  }
}

resource apiMgmtBackendRes 'Microsoft.ApiManagement/service/backends@2021-08-01'= {
  name: apiFuncName
  parent: apiMgmtRes
  properties: {
    description: apiFuncName
    url: 'https://${apiFuncName}.azurewebsites.net/api'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${skip(apiFuncId, 1)}'
    credentials: {
      header: {
        'x-functions-key': [ 
          '{{${apiFuncName}-key}}' 
        ]
      }
    }
  }
  dependsOn: [
    apiMgmtNamedValueKeyRes
  ]
}

resource apiMgmtNamedValueKeyRes 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  name: '${apiFuncName}-key'
  parent: apiMgmtRes
  properties: {
    displayName: '${apiFuncName}-key'
    value: apiMgmtFuncKeySecret
    secret: true
  }
}

resource apiMgmtApiRes 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: apiMgmtApiName
  parent: apiMgmtRes
  properties: {
    displayName: !empty(apiDefTitle) ? apiDefTitle : apiFuncName
    description: apiDefDescription
    subscriptionRequired: apiMgmtApiSubscriptionRequired
    path: apiMgmtApiRoute
    protocols: [
      'https'
    ]
    isCurrent: true
    apiType: 'http'
    apiVersion: 'v${apiDefVersionParts[0]}'
    apiVersionSetId: apiMgmtVersionSetRes.id
    apiRevision: '${int(apiDefVersionParts[1]) + 1}'
    apiRevisionDescription: 'API Definition: ${apiDefVersion}'
    format: 'openapi+json-link'
    value: apiSpecificationUrl
  }
}

resource apiMgmtApiPolicyRes 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  name: 'policy'
  parent: apiMgmtApiRes
  properties: {
    value: '<policies><inbound><base /><set-backend-service backend-id="${apiMgmtBackendRes.name}" /><set-header name="${apiVersionHeaderName}" exists-action="override"><value>${apiDefVersion}</value></set-header></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
    format: 'xml'
  }
}

// Note: This code below could be used to automatically make (new) APIs available to users by adding them to APIM Product(s).
//       Often we currently want an explicit, manual management of Users, Subscriptions and also Products in the Portal.
/*
resource apiMgmtProductRes 'Microsoft.ApiManagement/service/products@2021-08-01' existing = {
  parent: apiMgmtRes
  name: apiMgmtProductName
}

resource apiMgmtProductApiRes 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  parent: apiMgmtProductRes
  name: apiMgmtApiName
  dependsOn: [
    apiMgmtApiRes
  ]
}
*/
