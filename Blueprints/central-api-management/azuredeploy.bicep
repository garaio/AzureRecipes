@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

@allowed([
  'Developer'
  'Basic'
  // 'Standard' - Rather expensive
  // 'Premium' - This one is really expensive
])
param apiManagementSku string = 'Developer'
param apiManagementPublisherEmail string = 'it@customer.ch'
param apiManagementPublisherName string = 'Customer AG'

@description('Deploys Front Door setup for Developer Portal as well as some CORS-settings in the API Management')
param configureApiManagementDevPortal bool = false

param apiManagementDevPortalAadAppClientId string = ''
@secure()
param apiManagementDevPortalAadAppClientSecret string = ''

@description('The name of the SKU to use when creating the Front Door profile. If you use Private Link this must be set to `Premium_AzureFrontDoor`.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSku string = 'Standard_AzureFrontDoor'
param frontDoorSpnObjectId string = '00000000-0000-0000-0000-000000000000' // Created according to https://docs.microsoft.com/en-gb/azure/frontdoor/standard-premium/how-to-configure-https-custom-domain#register-azure-front-door and copy ObjectId (to be done once per tenant)

param customDomainApimApi string = 'int.api.customer.ch'
param customDomainApimPortal string = 'portal.api.customer.ch'

@description('If set to false, it deploys the KeyVault as fresh new instance including removal of all other access policies. If set to true, the KeyVault needs to be existing, otherwise an error is thrown.')
param useExistingKeyVault bool = true

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var appInsightsName = '${resourceNamePrefix}-ai-${resourceNameSuffix}'

// Key Vault is mainly deployed for later provisioning of custom SSL certificates
var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultMgmtPermissions = {
  secrets: [
    'get'
    'list'
  ]
  certificates: [
    'get'
    'getissuers'
    'list'
    'listissuers'
  ]
}

var apiMgmtName = '${resourceNamePrefix}-apim-${resourceNameSuffix}'
var apiMgmtFrontDoorIdNamedValueName = 'FrontDoorId'

var frontDoorName = '${resourceNamePrefix}-fd-${resourceNameSuffix}'
var frontDoorApiEndpoint = '${resourceNamePrefix}-fd-api-${resourceNameSuffix}'
var frontDoorDevPortalEndpoint = '${resourceNamePrefix}-fd-portal-${resourceNameSuffix}'
var frontDoorWafName = replace('${resourceNamePrefix}-fd-waf-${resourceNameSuffix}', '-', '')

resource partnerIdRes 'Microsoft.Resources/deployments@2020-06-01' = {
  name: 'pid-d16e7b59-716a-407d-96db-18d1cac40407'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsightsRes 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: resourceLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWsRes.id
  }
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    createMode: useExistingKeyVault ? 'recover' : 'default'
    accessPolicies: []
  }
}

resource keyVaultDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: keyVaultRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'AuditEvent'
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

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(apiMgmtRes.id, '2021-08-01', 'Full').identity.principalId
        permissions: keyVaultMgmtPermissions
      }
      {
        tenantId: subscription().tenantId
        objectId: frontDoorSpnObjectId
        permissions: frontDoorSpnObjectId != '' ? keyVaultMgmtPermissions : {}
      }
    ]
  }
}

resource apiMgmtRes 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiMgmtName
  location: resourceLocation
  sku: {
    name: apiManagementSku
    capacity: apiManagementSku == 'Consumption' ? 0 : 1
  }
  properties: {
    publisherEmail: apiManagementPublisherEmail
    publisherName: apiManagementPublisherName
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
      instrumentationKey: appInsightsRes.properties.InstrumentationKey
    }
    isBuffered: true
    resourceId: appInsightsRes.id
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
    workspaceId: logAnalyticsWsRes.id
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

resource apiMgmtIdentityProviderAadRes 'Microsoft.ApiManagement/service/identityProviders@2021-08-01' = if (configureApiManagementDevPortal && apiManagementDevPortalAadAppClientId != '') {
  parent: apiMgmtRes
  name: 'aad' // Alternative 'aadB2C'
  properties: {
    type: 'aad' // Alternative 'aadB2C'
    clientId: apiManagementDevPortalAadAppClientId
    clientSecret: apiManagementDevPortalAadAppClientSecret
    authority: environment().authentication.loginEndpoint // 'login.microsoftonline.com'
    signinTenant: subscription().tenantId
    allowedTenants: [
      subscription().tenantId
    ]
  }
}

resource apiMgmtNamedValueFrontDoorRes 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  parent: apiMgmtRes
  name: apiMgmtFrontDoorIdNamedValueName
  properties: {
    displayName: apiMgmtFrontDoorIdNamedValueName
    value: frontDoorRes.properties.frontDoorId
    secret: true
  }
}

// Officially, the Developer Portal only supports APIM being behind a Front Door, with a custom domain (type proxy/gateway) linked by both services.
// That solution is only possible with custom SSL certificate provisioning, which is incredible painful to be automated (and btw the Developer SKU doesn't support the Key Vault based autorenew).
// This hacky solution provides basically a redirection of API traffic caused within built-in Test view and Developer Portal to be routed via Front Door. And it handles CORS issues.
// For non-OPTIONS requests, basically a common HTTP redirection is made. As 301 turns everything into GET, we would need the 308 code (permanent) - but this is currently not supported in the built-in Test view, so we use a 307 (temporary) which also maintains HTTP methods
// Further this policy validates that traffic comes from the Front Door only (again, only for non OPTIONS requests)
resource apiMgmtBasePolicyRes 'Microsoft.ApiManagement/service/policies@2021-08-01' = {
  parent: apiMgmtRes
  name: 'policy'
  properties: {
    value: configureApiManagementDevPortal ? '<policies><inbound><cors allow-credentials="true" terminate-unmatched-request="false"><allowed-origins><origin>${apiMgmtRes.properties.developerPortalUrl}</origin><origin>https://${frontDoorEndpointDevPortalRes.properties.hostName}</origin><origin>https://${customDomainApimPortal}</origin></allowed-origins><allowed-methods preflight-result-max-age="300"><method>*</method></allowed-methods><allowed-headers><header>*</header></allowed-headers><expose-headers><header>*</header></expose-headers></cors><choose><when condition="@(context.Request.Method == &quot;OPTIONS&quot;)" /><when condition="@(context.Request.Headers.GetValueOrDefault(&quot;X-Azure-FDID&quot;,&quot;&quot;) == &quot;&quot;)"><return-response><set-status code="307" reason="Redirecting" /><set-header name="Location" exists-action="override"><value>@("https://${frontDoorEndpointApiRes.properties.hostName}" + context.Request.OriginalUrl.Path + context.Request.OriginalUrl.QueryString)</value></set-header></return-response></when><otherwise><check-header name="X-Azure-FDID" failed-check-httpcode="403" failed-check-error-message="Invalid request." ignore-case="false"><value>{{FrontDoorId}}</value></check-header></otherwise></choose></inbound><backend><forward-request /></backend></policies>' : '<policies><inbound><check-header name="X-Azure-FDID" failed-check-httpcode="403" failed-check-error-message="Invalid request." ignore-case="false"><value>{{${apiMgmtFrontDoorIdNamedValueName}}}</value></check-header></inbound><backend><forward-request /></backend></policies>'
    format: 'xml'
  }
  dependsOn: [
    apiMgmtNamedValueFrontDoorRes
  ]
}

resource frontDoorRes 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorName
  location: 'global'
  sku: {
    name: frontDoorSku
  }
}

resource frontDoorEndpointApiRes 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorApiEndpoint
  parent: frontDoorRes
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroupApiRes 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: 'api'
  parent: frontDoorRes
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource frontDoorOriginApiRes 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: 'ApiManagement'
  parent: frontDoorOriginGroupApiRes
  properties: {
    hostName: apiMgmtRes.properties.hostnameConfigurations[0].hostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: apiMgmtRes.properties.hostnameConfigurations[0].hostName
    priority: 1
    weight: 1000
  }
}

resource frontDoorDomainApiRes 'Microsoft.Cdn/profiles/customdomains@2021-06-01' = if (!empty(customDomainApimApi)) {
  name: replace(customDomainApimApi, '.', '-')
  parent: frontDoorRes
  properties: {
    hostName: customDomainApimApi
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

resource frontDoorEndpointRouteApiRes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'api-route'
  parent: frontDoorEndpointApiRes
  dependsOn: [
    frontDoorOriginApiRes // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    customDomains: [
      {
        id: frontDoorDomainApiRes.id
      }
    ]
    originGroup: {
      id: frontDoorOriginGroupApiRes.id
    }
    ruleSets: !configureApiManagementDevPortal ? [] : [
      {
        id: frontDoorRulesetDevPortalRes.id
      }
    ]
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

resource frontDoorRulesetDevPortalRes 'Microsoft.Cdn/profiles/rulesets@2021-06-01' = if(configureApiManagementDevPortal) {
  name: 'apimDevPortal'
  parent: frontDoorRes
}

// API Management Developer Portal completely fails to make CORS-proper calls when receiving a 3xx redirection - these rules fixes it by transforming request and response headers
// Info: The conditional references inside this resource are necessary because of this Bicep/ARM bug: https://github.com/Azure/bicep/issues/3990
resource frontDoorRulesetDevPortalDefaultHostCorsRuleRes 'Microsoft.Cdn/profiles/rulesets/rules@2021-06-01' = if(configureApiManagementDevPortal) {
  name: 'DefaultHostCors'
  parent: frontDoorRulesetDevPortalRes
  properties: {
    order: 1
    conditions: [
      {
        name: 'RequestHeader'
        parameters: {
          typeName: 'DeliveryRuleRequestHeaderConditionParameters'
          operator: 'BeginsWith'
          selector: 'Referer'
          negateCondition: false
          matchValues: [
            configureApiManagementDevPortal ? 'https://${frontDoorEndpointDevPortalRes.properties.hostName}' : ''
          ]
          transforms: [
            'Lowercase'
            'Trim'
          ]
        }
      }
      {
        name: 'RequestHeader'
        parameters: {
          typeName: 'DeliveryRuleRequestHeaderConditionParameters'
          operator: 'Equal'
          selector: 'Origin'
          negateCondition: false
          matchValues: [
            'null'
          ]
          transforms: [
            'Lowercase'
            'Trim'
          ]
        }
      }
    ]
    actions: [
      {
        name: 'ModifyRequestHeader'
        parameters: {
          typeName: 'DeliveryRuleHeaderActionParameters'
          headerAction: 'Overwrite'
          headerName: 'Origin'
          value: configureApiManagementDevPortal ? 'https://${frontDoorEndpointDevPortalRes.properties.hostName}' : ''
        }
      }
      {
        name: 'ModifyResponseHeader'
        parameters: {
          typeName: 'DeliveryRuleHeaderActionParameters'
          headerAction: 'Overwrite'
          headerName: 'Access-Control-Allow-Origin'
          value: 'null'
        }
      }
    ]
    matchProcessingBehavior: 'Continue'
  }
}

resource frontDoorRulesetDevPortalCustomDomainCorsRuleRes 'Microsoft.Cdn/profiles/rulesets/rules@2021-06-01' = if(configureApiManagementDevPortal && !empty(customDomainApimPortal)) {
  name: 'CustomDomainCors'
  parent: frontDoorRulesetDevPortalRes
  properties: {
    order: 2
    conditions: [
      {
        name: 'RequestHeader'
        parameters: {
          typeName: 'DeliveryRuleRequestHeaderConditionParameters'
          operator: 'BeginsWith'
          selector: 'Referer'
          negateCondition: false
          matchValues: [
            'https://${customDomainApimPortal}'
          ]
          transforms: [
            'Lowercase'
            'Trim'
          ]
        }
      }
      {
        name: 'RequestHeader'
        parameters: {
          typeName: 'DeliveryRuleRequestHeaderConditionParameters'
          operator: 'Equal'
          selector: 'Origin'
          negateCondition: false
          matchValues: [
            'null'
          ]
          transforms: [
            'Lowercase'
            'Trim'
          ]
        }
      }
    ]
    actions: [
      {
        name: 'ModifyRequestHeader'
        parameters: {
          typeName: 'DeliveryRuleHeaderActionParameters'
          headerAction: 'Overwrite'
          headerName: 'Origin'
          value: 'https://${customDomainApimPortal}'
        }
      }
      {
        name: 'ModifyResponseHeader'
        parameters: {
          typeName: 'DeliveryRuleHeaderActionParameters'
          headerAction: 'Overwrite'
          headerName: 'Access-Control-Allow-Origin'
          value: 'null'
        }
      }
    ]
    matchProcessingBehavior: 'Continue'
  }
}

resource frontDoorEndpointDevPortalRes 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = if(configureApiManagementDevPortal) {
  name: frontDoorDevPortalEndpoint
  parent: frontDoorRes
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroupDevPortalRes 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = if(configureApiManagementDevPortal) {
  name: 'developer-portal'
  parent: frontDoorRes
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource frontDoorOriginDevPortalRes 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = if(configureApiManagementDevPortal) {
  name: 'DeveloperPortal'
  parent: frontDoorOriginGroupDevPortalRes
  properties: {
    hostName: replace(apiMgmtRes.properties.developerPortalUrl, 'https://', '')
    httpPort: 80
    httpsPort: 443
    originHostHeader: replace(apiMgmtRes.properties.developerPortalUrl, 'https://', '')
    priority: 1
    weight: 1000
  }
}

resource frontDoorDomainDevPortalRes 'Microsoft.Cdn/profiles/customdomains@2021-06-01' = if(configureApiManagementDevPortal && !empty(customDomainApimPortal)) {
  name: replace(customDomainApimPortal, '.', '-')
  parent: frontDoorRes
  properties: {
    hostName: customDomainApimPortal
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

resource frontDoorEndpointRouteDevPortalRes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = if(configureApiManagementDevPortal) {
  name: 'developer-portal-route'
  parent: frontDoorEndpointDevPortalRes
  dependsOn: [
    frontDoorOriginDevPortalRes // This explicit dependency is required to ensure that the origin group is not empty when the route is created.
  ]
  properties: {
    customDomains: [
      {
        id: frontDoorDomainDevPortalRes.id
      }
    ]
    originGroup: {
      id: frontDoorOriginGroupDevPortalRes.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
}

resource frontDoorWafRes 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: frontDoorWafName
  location: 'global'
  sku: {
    name: frontDoorSku
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
    }
    managedRules: {
      managedRuleSets: []
    }
  }
}

resource frontDoorWafPolicyRes 'Microsoft.Cdn/profiles/securityPolicies@2021-06-01' = {
  name: 'waf-policy'
  parent: frontDoorRes
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: frontDoorWafRes.id
      }
      associations: [
        {
          domains: union(!configureApiManagementDevPortal ? [] : [
            {
              id: frontDoorEndpointDevPortalRes.id  
            }
          ], [
            {
              id: frontDoorEndpointApiRes.id
            }
          ])
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

resource frontDoorDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: frontDoorRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'FrontDoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontDoorHealthProbeLog'
        enabled: true
      }
      {
        category: 'FrontDoorWebApplicationFirewallLog'
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

output keyVaultName string = keyVaultRes.id
output apiManagementId string = apiMgmtRes.id

output frontDoorApiEndpointHostName string = frontDoorEndpointApiRes.properties.hostName
output frontDoorApiDnsTxtRecordName string = '_dnsauth.${frontDoorDomainApiRes.properties.hostName}'
output frontDoorApiDnsTxtRecordValue string = frontDoorDomainApiRes.properties.validationProperties.validationToken
output frontDoorApiDnsExpiry string = frontDoorDomainApiRes.properties.validationProperties.expirationDate

output frontDoorDeveloperPortalEndpointHostName string = configureApiManagementDevPortal ? frontDoorEndpointDevPortalRes.properties.hostName : ''
output frontDoorDeveloperPortalDnsTxtRecordName string = configureApiManagementDevPortal ? '_dnsauth.${frontDoorDomainDevPortalRes.properties.hostName}' : ''
output frontDoorDeveloperPortalDnsTxtRecordValue string = configureApiManagementDevPortal ? frontDoorDomainDevPortalRes.properties.validationProperties.validationToken : ''
output frontDoorDeveloperPortalDnsExpiry string = configureApiManagementDevPortal ? frontDoorDomainDevPortalRes.properties.validationProperties.expirationDate : ''
