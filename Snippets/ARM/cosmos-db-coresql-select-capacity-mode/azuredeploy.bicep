@description('The prefix will be used for every parameter that represents a resource name.')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every resource name. You have to specify a unique, not yet used, value.')
param resourceNameSuffix string

@description('Can only be activated once per subscription. Ignored when Synapse Workspace is not deployed (then serverless tier is choosen).')
param cosmosDbEnableFreeTier bool = false

@description('Only considered if free tier is not activated and Synapse Workspace is deployed.')
param cosmosDbEnableAutoscale bool = true

@description('Applied when not autoscale or serverless tier is active.')
@minValue(400)
@maxValue(4000)
param cosmosDbProvisionedThroughput int = 400

@description('If disabled, Cosmos DB will be deployed in serverless tier (not supported with Synapse Link).')
param cosmosDbEnableSynapseLink bool = true

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'

var cosmosDbAccountName = '${resourceNamePrefix}-cdb-${resourceNameSuffix}'
var cosmosDbDatabase = 'DemoData'
var cosmosDbContainers = [
  'Foo'
  'Bar'
]
var cosmosDbSettingFreeTier = !cosmosDbEnableSynapseLink && cosmosDbEnableFreeTier
var cosmosDbSettingCapabilities = !cosmosDbEnableSynapseLink ? [
  {
    name: 'EnableServerless'
  }
] : []
var cosmosDbScaleOptions = !cosmosDbSettingFreeTier && cosmosDbEnableAutoscale ? {
  autoscaleSettings: {
    maxThroughput: 4000
  }
} : {
  throughput: cosmosDbProvisionedThroughput
}
var cosmosDbSettingOptions = cosmosDbEnableSynapseLink ? cosmosDbScaleOptions : {}
var cosmosDbSettingBackupPolicy = cosmosDbEnableSynapseLink ? {
  type: 'Periodic'
  periodicModeProperties: {
    backupIntervalInMinutes: 240
    backupRetentionIntervalInHours: 8
  }
} : {
  type: 'Continuous'
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
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource cosmosDbAccountRes 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: cosmosDbAccountName
  location: resourceGroup().location
  kind: 'GlobalDocumentDB'
  properties: {
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    enableFreeTier: cosmosDbSettingFreeTier
    enableAnalyticalStorage: cosmosDbEnableSynapseLink
    createMode: 'Default'
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: resourceGroup().location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]    
    capabilities: cosmosDbSettingCapabilities
    backupPolicy: cosmosDbSettingBackupPolicy
  }
}

resource cosmosDbAccountDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: cosmosDbAccountRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyRUConsumption'
        enabled: true
      }
      {
        category: 'ControlPlaneRequests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
  dependsOn: [
    cosmosDbAccountRes
  ]
}

resource cosmosDbDatabaseRes 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: '${cosmosDbAccountRes.name}/${cosmosDbDatabase}'
  properties: {
    resource: {
      id: cosmosDbDatabase
    }
    options: cosmosDbSettingOptions
  }
  dependsOn: [
    cosmosDbAccountRes
  ]
}

resource cosmosDbContainersRes 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = [for item in cosmosDbContainers: {
  name: '${cosmosDbAccountRes.name}/${cosmosDbDatabase}/${item}'
  properties: {
    resource: {
      id: item
      indexingPolicy: {
        automatic: true
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/PartitionKey'
        ]
        kind: 'Hash'
      }
      conflictResolutionPolicy: {
        mode: 'LastWriterWins'
        conflictResolutionPath: '/_ts'
      }      
      analyticalStorageTtl: cosmosDbEnableSynapseLink ? -1 : 0 // https://docs.microsoft.com/en-us/azure/cosmos-db/analytical-store-introduction#analytical-ttl
    }
  }
  dependsOn: [
    cosmosDbDatabaseRes
  ]
}]

output cosmosAccountConnectionString string = listConnectionStrings(cosmosDbAccountRes.id, '2021-06-15').connectionStrings[0].connectionString
