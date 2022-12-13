@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param sqlServerAdminUsername string = 'customer-admin'
@secure()
param sqlServerAdminPassword string
@allowed([
  'GP_S_Gen5_1' // 0.5-1 Cores  | < 450 CHF/month (Switzerland North)
  'GP_S_Gen5_2' // 0.5-2 Cores  | < 900 CHF/month (Switzerland North)
  'GP_S_Gen5_4' // 0.5-4 Cores  | < 1800 CHF/month (Switzerland North)
  'GP_S_Gen5_6' // 0.75-6 Cores | < 2700 CHF/month (Switzerland North)
  'GP_S_Gen5_8' // 1-8 Cores    | < 3600 CHF/month (Switzerland North)
])
param sqlDatabaseSku string = 'GP_S_Gen5_2'
@minValue(1)
param sqlDatabaseMaxSizeInGb int = 100
@description('If either geo-replication or long-term backup retention shall be enabled, this value has to be \'-1\', which disables pausing functionality (and thus removes a key benefit from serverless mode)')
param sqlDatabaseAutoPauseDelayInMinutes int = 60 // https://docs.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview?view=azuresql#auto-pausing
@description('If auto-pausing is enabled, this is not supported')
param sqlDatabaseEnableBackupLtr bool = false

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

var sqlServerName = '${resourceNamePrefix}-sql-${resourceNameSuffix}'
var sqlDatabaseName = '${resourceNamePrefix}-sqldb-${resourceNameSuffix}'
// See https://docs.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-single-databases?view=azuresql#general-purpose---serverless-compute---gen5
var sqlDatabaseSkuDetails = {
  GP_S_Gen5_1: { 
    min: json('0.5')
    max: 1
  }
  GP_S_Gen5_2: { 
    min: json('0.5')
    max: 2
  }
  GP_S_Gen5_4: { 
    min: json('0.5')
    max: 4
  }
  GP_S_Gen5_6: { 
    min: json('0.75')
    max: 6
  }
  GP_S_Gen5_8: { 
    min: json('1.0')
    max: 8
  }
}

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

resource sqlServerRes 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName
  location: resourceLocation
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

resource sqlServerFirewallRuleRes 'Microsoft.Sql/servers/firewallRules@2022-02-01-preview' = {
  parent: sqlServerRes
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerAutoTuningCreateIndexRes 'Microsoft.Sql/servers/advisors@2014-04-01' = if (false) { // Note: Despite documented, this is currently not supported via ARM (activate it manually in the portal)
  parent: sqlServerRes
  name: 'CreateIndex'
  properties: {
    autoExecuteValue: 'Enabled'
  }
}

resource sqlServerAutoTuningDropIndexRes 'Microsoft.Sql/servers/advisors@2014-04-01' = if (false) { // Note: Despite documented, this is currently not supported via ARM (activate it manually in the portal)
  parent: sqlServerRes
  name: 'DropIndex'
  properties: {
    autoExecuteValue: 'Enabled'
  }
}

resource sqlServerAutoTuningForcePlanRes 'Microsoft.Sql/servers/advisors@2014-04-01' = if (false) { // Note: Despite documented, this is currently not supported via ARM (activate it manually in the portal)
  parent: sqlServerRes
  name: 'ForceLastGoodPlan'
  properties: {
    autoExecuteValue: 'Enabled'
  }
}

resource sqlDatabaseRes 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: sqlServerRes
  name: sqlDatabaseName
  location: resourceLocation
  sku: {
    name: 'GP_S_Gen5'
    capacity: sqlDatabaseSkuDetails[sqlDatabaseSku].max
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    highAvailabilityReplicaCount: 0
    maxSizeBytes: sqlDatabaseMaxSizeInGb * 1073741824 // Note: 1 kilobyte = 1024 bytes
    zoneRedundant: false
    readScale: 'Disabled'
    autoPauseDelay: sqlDatabaseAutoPauseDelayInMinutes
    requestedBackupStorageRedundancy: 'Geo'
    minCapacity: sqlDatabaseSkuDetails[sqlDatabaseSku].min
    isLedgerOn: false
    licenseType: null // Note: Serverless plan does not (yet) support this -> no hybrid benefit available 
  }
}

resource sqlDatabaseGeoBackupRes 'Microsoft.Sql/servers/databases/geoBackupPolicies@2014-04-01' = { // Note: Despite officially documented, newer versions such as '2022-02-01-preview' are not supported and fail on deployment
  parent: sqlDatabaseRes
  name: 'Default'
  properties: {
    state: 'Enabled'
  }
}

// Note 1: If long-term backup retention (LTR) is enabled, auto-pausing must be deactivated (set value to '-1')
// Note 2: It is not possible to disable LTR via ARM deployment, once it has been activated
resource sqlDatabaseLtrBackupRes 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2022-02-01-preview' = if (sqlDatabaseEnableBackupLtr) {
  parent: sqlDatabaseRes
  name: 'default'
  properties: {
    weeklyRetention: 'PT0S'
    monthlyRetention: 'PT0S'
    yearlyRetention: 'PT0S'
    weekOfYear: 1 // Defines when to take the yearly backup, must be between 1 and 52 (validated on deployment) or omitted along with 'yearlyRetention'
  }
}

resource sqlDatabaseStrBackupRes 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2022-02-01-preview' = {
  parent: sqlDatabaseRes
  name: 'default'
  properties: {
    retentionDays: 14
    diffBackupIntervalInHours: 24
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
}

#disable-next-line outputs-should-not-contain-secrets
output sqlDatabaseConnectionString string = 'Server=tcp:${reference(sqlServerName).fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlServerAdminUsername};Password=${sqlServerAdminPassword};Connection Timeout=30;'
