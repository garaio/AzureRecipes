param resourceLocation string = resourceGroup().location

resource function_name 'Microsoft.Web/sites@2020-09-01' = {
  kind: 'functionapp'
  name: '<function-name>'
  location: resourceLocation
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '<function-name>.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '<function-name>.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    clientAffinityEnabled: true
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    siteConfig: {
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: []
}

resource function_name_appsettings 'Microsoft.Web/sites/config@2020-09-01' = {
  parent: function_name
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: '<storage-account-connection-string>'
    AzureWebJobsDisableHomepage: 'true'
    WEBSITE_TIME_ZONE: 'W. Europe Standard Time'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '<storage-account-connection-string>'
    WEBSITE_CONTENTSHARE: '<function-name>'
    APPINSIGHTS_INSTRUMENTATIONKEY: '<app-insights-instrumentation-key>'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  }
}
