
@description('The prefix will be used for every parameter that represents a resource name.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name.')
param resourceNameSuffix string

@allowed([
  'S0' // 10 DTUs, ~ 20 CHF
  'S1' // 20 DTUs, ~ 45 CHF
  'S2' // 50 DTUs, ~ 115 CHF
  'S3' // 100 DTUs, ~ 225 CHF
])
param sqlServerSku string = 'S0'
param sqlServerAdminUsername string = 'customer-admin'
@secure()
param sqlServerAdminPassword string

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

var sqlServerName = '${resourceNamePrefix}-sql-${resourceNameSuffix}'
var sqlDatabaseName = '${resourceNamePrefix}-sqldb-${resourceNameSuffix}'

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
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource sqlServerRes 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlServerName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlServerAdminUsername
    administratorLoginPassword: sqlServerAdminPassword
    minimalTlsVersion: '1.2'
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource sqlServerFirewallRuleRes 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqlServerRes
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabaseRes 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  parent: sqlServerRes
  name: sqlDatabaseName
  location: resourceGroup().location
  sku: {
    name: sqlServerSku
    tier: 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    highAvailabilityReplicaCount: 0
    isLedgerOn: false
    maxSizeBytes: 268435456000
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Geo'
    zoneRedundant: false
  }
}

resource sqlDatabaseDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: sqlDatabaseRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
    ]
  }
  dependsOn: [
    sqlDatabaseRes
  ]
}

output sqlDatabaseConnectionString string = 'Server=tcp:${reference(sqlServerName).fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlServerAdminUsername};Password=${sqlServerAdminPassword};Connection Timeout=30;'
