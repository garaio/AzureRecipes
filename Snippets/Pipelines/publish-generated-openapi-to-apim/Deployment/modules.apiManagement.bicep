param resourceLocation string = resourceGroup().location

param apiMgmtName string
param apiMgmtSku string
param apiMgmtPublisherEmail string
param apiMgmtPublisherName string
param apiMgmtGatewayCustomDomain string

param appInsightsResId string

param logAnalyticsWsId string

var appInsightsResIdParts = split(appInsightsResId, '/') // Indexes: 2 = SubscriptionId, 4 = ResourceGroupName, 8 = ResourceName

resource appInsightsRes 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsResIdParts[8]
}

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
    hostnameConfigurations: empty(apiMgmtGatewayCustomDomain) ? [] : [
      {
        hostName: '${apiMgmtName}.azure-api.net'
        type: 'Proxy'
        negotiateClientCertificate: false
        defaultSslBinding: false
        certificateSource: 'BuiltIn'
      }
      // Currently Azure-managed (free) certificates for custom domains are available only for Gateway endpoints (i.e. not Developer Portal endpoints).
      // More information see https://learn.microsoft.com/en-us/azure/api-management/configure-custom-domain?tabs=managed#domain-certificate-options
      {
        hostName: apiMgmtGatewayCustomDomain
        type: 'Proxy'
        negotiateClientCertificate: false
        defaultSslBinding: true
        certificateSource: 'Managed'
      }
    ]
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apiMgmtServiceLoggerRes 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  parent: apiMgmtRes
  name: appInsightsRes.name
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: appInsightsRes.properties.InstrumentationKey // Despite migrated to connection-string in other places, this is still documented to require the key - but may change in future
    }
    isBuffered: true
    resourceId: appInsightsResId
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

output apiMgmtResId string = apiMgmtRes.id
output apiMgmtDevPortalUrl string = apiMgmtRes.properties.developerPortalUrl
