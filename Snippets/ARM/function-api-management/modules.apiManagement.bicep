param resourceLocation string = resourceGroup().location

param apiMgmtName string
param apiMgmtSku string
param apiMgmtPublisherEmail string
param apiMgmtPublisherName string
param apiMgmtVersionDescription string = 'Release Date: ${utcNow('d')}'

@secure()
param apiMgmtFuncKeySecret string

param templateFuncId string
param templateFuncName string

param appInsightsId string
param appInsightsName string

param logAnalyticsWsId string

@secure()
param monitoringSubscriptionKey string = base64(newGuid())

var apiMgmtInternalApiName = 'template'
var apiMgmtTemplateApi = 'test-api'
var apiMgmtTemplateApiDisplayName = 'Test API'
var apiMgmtTemplateApiPath = 'test'
var apiMgmtTemplateProduct = 'test-product'
var apiMgmtTemplateProductDisplayName = 'Test API Integration'

resource apiMgmtRes 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiMgmtName
  location: resourceLocation
  sku: {
    name: apiMgmtSku
    capacity: 1
  }
  properties: {
    publisherEmail: apiMgmtPublisherEmail
    publisherName: apiMgmtPublisherName
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apiMgmtServiceLoggerRes 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  parent: apiMgmtRes
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: reference(appInsightsId, '2015-05-01').InstrumentationKey
    }
    isBuffered: true
    resourceId: appInsightsId
  }
}

resource apiMgmtServiceDiagnosticsRes 'Microsoft.ApiManagement/service/diagnostics@2021-08-01' = {
  parent: apiMgmtRes
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    loggerId: apiMgmtServiceLoggerRes.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
  }
}

resource apiMgmtDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: apiMgmtRes
  properties: {
    workspaceId: logAnalyticsWsId
    logs: [
      {
        category: 'GatewayLogs'
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

resource apiMgmtBasePolicyRes 'Microsoft.ApiManagement/service/policies@2021-08-01' = {
  parent: apiMgmtRes
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <set-query-parameter name="subscriptionId" exists-action="override">\r\n      <value>@(context.Subscription.Id)</value>\r\n    </set-query-parameter>\r\n    <set-query-parameter name="userId" exists-action="override">\r\n      <value>@(context.User.Id)</value>\r\n    </set-query-parameter>\r\n    <cors>\r\n        <allowed-origins>\r\n        <origin>*</origin>\r\n        </allowed-origins>\r\n        <allowed-methods>\r\n        <method>*</method>\r\n        </allowed-methods>\r\n        <allowed-headers>\r\n        <header>*</header>\r\n        </allowed-headers>\r\n        <expose-headers>\r\n        <header>*</header>\r\n        </expose-headers>\r\n    </cors>\r\n  </inbound>\r\n  <backend>\r\n    <forward-request />\r\n  </backend>\r\n  <outbound />\r\n  <on-error />\r\n</policies>'
    format: 'xml'
  }
}

resource apiMgmtTemplateBackendRes 'Microsoft.ApiManagement/service/backends@2021-08-01' = {
  parent: apiMgmtRes
  name: '${apiMgmtInternalApiName}-backend'
  properties: {
    description: templateFuncName
    url: 'https://${templateFuncName}.azurewebsites.net/api'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${skip(templateFuncId, 1)}'
    credentials: {
      header: {
        'x-functions-key': [ 
          apiMgmtFuncKeySecret 
        ]
      }
    }
  }
}

resource apiMgmtTemplateApiRes 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  parent: apiMgmtRes
  name: apiMgmtTemplateApi
  properties: {
    displayName: apiMgmtTemplateApiDisplayName
    apiRevision: '1'
    apiVersionDescription: apiMgmtVersionDescription
    subscriptionRequired: true
    path: apiMgmtTemplateApiPath
    protocols: [
      'https'
    ]
    isCurrent: true
  }
}

resource apiMgmtTemplateApiPolicyRes 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  parent: apiMgmtTemplateApiRes
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <set-backend-service backend-id="${apiMgmtInternalApiName}-backend" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    apiMgmtTemplateBackendRes
  ]
}

resource apiMgmtTemplateApiSchemaRes 'Microsoft.ApiManagement/service/apis/schemas@2021-08-01' = {
  parent: apiMgmtTemplateApiRes
  name: '${apiMgmtInternalApiName}-schema'
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {
      components: {
        schemas: {
          RequestObject: {
            required: [
              'intProperty'
            ]
            type: 'object'
            properties: {
              intProperty: {
                maximum: 2
                minimum: 1
                type: 'integer'
                description: 'The value must be either 1 or 2'
              }
              stringProperty: {
                type: 'string'
                description: 'Any additional text informing about content or purpose of the message'
              }
            }
            example: {
              intProperty: 2
              messageTypeInfo: 'Message XYZ'
            }
          }
          ResponseObject: {
            required: [
              'transferStatusCode'
            ]
            type: 'object'
            properties: {
              transferId: {
                type: 'string'
              }
              transferTimestamp: {
                type: 'string'
                format: 'date-time'
              }
              transferStatusCode: {
                type: 'integer'
                minimum: 0
                maximum: 4
              }
              transferStatusInfo: {
                type: 'string'
              }
            }
            example: {
              transferId: '1aa41d46-1edb-487c-acc8-9e3d6151da1e'
              transferTimestamp: '2020-01-01T23:28:56Z'
              transferStatusCode: 0
              transferStatusInfo: 'Request accepted'
            }
          }
        }
        securitySchemes: {
          apiKeyHeader: {
            type: 'apiKey'
            name: 'Ocp-Apim-Subscription-Key'
            in: 'header'
          }
          apiKeyQuery: {
            type: 'apiKey'
            name: 'subscription-key'
            in: 'query'
          }
        }
      }
    }
  }
}

resource apiMgmtTemplateApiOperationsRes 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  parent: apiMgmtTemplateApiRes
  name: 'test'
  properties: {
    displayName: 'Test'
    method: 'POST'
    urlTemplate: '/testapi'
    templateParameters: []
    description: 'An example to show setup of API Management with Azure Functions'
    request: {
      description: 'Test API with some values'
      queryParameters: [
        {
          name: 'testParam'
          description: 'Test only'
          type: 'boolean'
          required: false
          values: []
        }
      ]
      headers: []
      representations: [
        {
          contentType: 'application/json'
          schemaId: '${apiMgmtInternalApiName}-schema'
          typeName: 'RequestObject'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Successfully processed'
        representations: [
          {
            contentType: 'application/json'
            schemaId: '${apiMgmtInternalApiName}-schema'
            typeName: 'ResponseObject'
          }
        ]
        headers: []
      }
      {
        statusCode: 400
        description: 'Failure'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
        headers: []
      }
    ]
  }
}

resource apiMgmtTemplateApiOperationsPolicyRes 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = {
  parent: apiMgmtTemplateApiOperationsRes
  name: 'policy'
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <rewrite-uri template="/testfunction" copy-unmatched-params="true" />\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

resource apiMgmtTemplateProductRes 'Microsoft.ApiManagement/service/products@2021-08-01' = {
  parent: apiMgmtRes
  name: apiMgmtTemplateProduct
  properties: {
    displayName: apiMgmtTemplateProductDisplayName
    description: 'Provide Azure Function endpoints'
    subscriptionRequired: true
    approvalRequired: true
    state: 'published'
  }
}

resource apiMgmtTemplateProductApiRes 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
  parent: apiMgmtTemplateProductRes
  name: apiMgmtTemplateApi
  dependsOn: [
    apiMgmtTemplateApiRes
  ]
}

resource apiMgmtTemplateProductGroupRes 'Microsoft.ApiManagement/service/products/groups@2021-08-01' = {
  parent: apiMgmtTemplateProductRes
  name: 'developers'
}

resource apiMgmtMonitoringSubscriptionRes 'Microsoft.ApiManagement/service/subscriptions@2021-08-01' = if (!empty(monitoringSubscriptionKey)) {
  name: 'monitoring'
  parent: apiMgmtRes
  properties: {
    allowTracing: false
    displayName: 'Monitoring (internal)'
    ownerId: '/users/1' // Predefined administrator account (if not deleted manually)
    primaryKey: monitoringSubscriptionKey
    scope: '/products/${apiMgmtTemplateProduct}' // Predefined product (if not deleted manually) : '/products/unlimited' -> Not used here to not expose security risks
    secondaryKey: null // Will be generated automatically
    state: 'active'
  }
}

output apiMgmtResId string = apiMgmtRes.id
// output monitoringSubscriptionKey string = apiMgmtMonitoringSubscriptionRes.listSecrets().primaryKey
