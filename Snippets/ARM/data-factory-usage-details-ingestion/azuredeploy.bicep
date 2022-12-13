@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param analyticsServicePrincipalId string

@secure()
param analyticsServicePrincipalSecret string

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var dataFactoryName = '${resourceNamePrefix}-df-${resourceNameSuffix}'

var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretAnalyticsServicePrincipalSecret = 'analyticsServicePrincipalSecret'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultKeyValuePairSecrets = [
  {
    name: keyVaultSecretAnalyticsServicePrincipalSecret
    value: analyticsServicePrincipalSecret
  }
]

var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')

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

resource storageAccountRes 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: resourceLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource logAnalyticsWsRes 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWsName
  location: resourceLocation
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
  }
}

resource keyVaultRes 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: resourceLocation
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    enableSoftDelete: true // With default of softDeleteRetentionInDays = 90
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

resource keyVaultAccessPoliciesRes 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyVaultRes
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(dataFactoryRes.id, '2018-06-01', 'Full').identity.principalId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource keyVaultSecretsFromArrayRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for item in keyVaultKeyValuePairSecrets: {
  name: '${keyVaultName}/${item.name}'
  properties: {
    value: item.value
  }
  dependsOn: [
    keyVaultRes
  ]
}]

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource dataFactoryRes 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: resourceLocation
  properties: {
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataFactoryDiagnosticsRes 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  name: 'LogAnalytics'
  scope: dataFactoryRes
  properties: {
    workspaceId: logAnalyticsWsRes.id
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
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

resource dataFactoryLinkedSvcKeyVaultRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'AzureKeyVault'
  properties: {
    annotations: []
    type: 'AzureKeyVault'
    typeProperties: {
      baseUrl: 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/'
    }
  }
  dependsOn: [
    keyVaultRes
  ]
}

resource dataFactoryPipelineExportAndAggregateUsageDetailsToTableRes 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactoryRes
  name: 'ExportAndAggregateUsageDetailsToTable'
  properties: {
    activities: [
      {
        name: 'LoadToBlob'
        type: 'Copy'
        dependsOn: []
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: [
          {
            name: 'Source'
            value: '?api-version=2019-01-01'
          }
          {
            name: 'Destination'
            value: 'exports//'
          }
        ]
        typeProperties: {
          source: {
            type: 'RestSource'
            httpRequestTimeout: '00:01:40'
            requestInterval: '00.00:00:00.010'
            requestMethod: 'GET'
            paginationRules: {
              AbsoluteUrl: '$.nextLink'
            }
          }
          sink: {
            type: 'JsonSink'
            storeSettings: {
              type: 'AzureBlobStorageWriteSettings'
            }
            formatSettings: {
              type: 'JsonWriteSettings'
              quoteAllText: true
              filePattern: 'setOfObjects'
            }
          }
          enableStaging: false
          translator: {
            type: 'TabularTranslator'
            mappings: [
              {
                source: {
                  path: '[\'name\']'
                }
                sink: {
                  path: '$[\'id\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'usageStart\']'
                }
                sink: {
                  path: '$[\'date\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'instanceId\']'
                }
                sink: {
                  path: '$[\'resourceId\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'instanceName\']'
                }
                sink: {
                  path: '$[\'resourceName\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'instanceLocation\']'
                }
                sink: {
                  path: '$[\'location\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'meterId\']'
                }
                sink: {
                  path: '$[\'meterId\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'usageQuantity\']'
                }
                sink: {
                  path: '$[\'usageQuantity\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'pretaxCost\']'
                }
                sink: {
                  path: '$[\'pretaxCost\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'currency\']'
                }
                sink: {
                  path: '$[\'currency\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'isEstimated\']'
                }
                sink: {
                  path: '$[\'isEstimated\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'subscriptionGuid\']'
                }
                sink: {
                  path: '$[\'subscriptionGuid\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'consumedService\']'
                }
                sink: {
                  path: '$[\'resourceTypeName\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'resourceGuid\']'
                }
                sink: {
                  path: '$[\'resourceTypeGuid\']'
                }
              }
              {
                source: {
                  path: '[\'properties\'][\'offerId\']'
                }
                sink: {
                  path: '$[\'offerId\']'
                }
              }
            ]
            collectionReference: '$[\'value\']'
          }
        }
        inputs: [
          {
            referenceName: 'UsageDetailsApiResponse'
            type: 'DatasetReference'
            parameters: {
            }
          }
        ]
        outputs: [
          {
            referenceName: 'UsageDetailsRawBlob'
            type: 'DatasetReference'
            parameters: {
              UsageDetailsExportContainer: 'exports'
              UsageDetailsRawBlobName: 'usage-details.json'
            }
          }
        ]
      }
      {
        name: 'AggregateData'
        type: 'ExecuteDataFlow'
        dependsOn: [
          {
            activity: 'LoadToBlob'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          dataFlow: {
            referenceName: 'AggregateUsageDetails'
            type: 'DataFlowReference'
            parameters: {
            }
            datasetParameters: {
              blobData: {
              }
              tableData: {
              }
            }
          }
          staging: {
          }
          compute: {
            coreCount: 8
            computeType: 'General'
          }
        }
      }
      {
        name: 'WriteToTable'
        type: 'Copy'
        dependsOn: [
          {
            activity: 'AggregateData'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          source: {
            type: 'DelimitedTextSource'
            storeSettings: {
              type: 'AzureBlobStorageReadSettings'
              recursive: true
              wildcardFileName: 'usage-details.csv'
              enablePartitionDiscovery: false
            }
            formatSettings: {
              type: 'DelimitedTextReadSettings'
            }
          }
          sink: {
            type: 'AzureTableSink'
            azureTableInsertType: 'replace'
            azureTablePartitionKeyName: 'partitionKey'
            azureTableRowKeyName: 'date'
            writeBatchSize: 10000
          }
          enableStaging: false
          translator: {
            type: 'TabularTranslator'
            mappings: [
              {
                source: {
                  name: 'partitionKey'
                  type: 'String'
                }
                sink: {
                  name: 'partitionKey'
                }
              }
              {
                source: {
                  name: 'meterId'
                  type: 'String'
                }
                sink: {
                  name: 'meterId'
                }
              }
              {
                source: {
                  name: 'resourceName'
                  type: 'String'
                }
                sink: {
                  name: 'resourceName'
                }
              }
              {
                source: {
                  name: 'date'
                  type: 'String'
                }
                sink: {
                  name: 'date'
                }
              }
              {
                source: {
                  name: 'usageQuantity'
                  type: 'String'
                }
                sink: {
                  name: 'usageQuantity'
                }
              }
              {
                source: {
                  name: 'pretaxCost'
                  type: 'String'
                }
                sink: {
                  name: 'pretaxCost'
                }
              }
              {
                source: {
                  name: 'id'
                  type: 'String'
                }
                sink: {
                  name: 'id'
                }
              }
              {
                source: {
                  name: 'resourceId'
                  type: 'String'
                }
                sink: {
                  name: 'resourceId'
                }
              }
              {
                source: {
                  name: 'location'
                  type: 'String'
                }
                sink: {
                  name: 'location'
                }
              }
              {
                source: {
                  name: 'currency'
                  type: 'String'
                }
                sink: {
                  name: 'currency'
                }
              }
              {
                source: {
                  name: 'isEstimated'
                  type: 'String'
                }
                sink: {
                  name: 'isEstimated'
                }
              }
              {
                source: {
                  name: 'subscriptionGuid'
                  type: 'String'
                }
                sink: {
                  name: 'subscriptionGuid'
                }
              }
              {
                source: {
                  name: 'resourceTypeName'
                  type: 'String'
                }
                sink: {
                  name: 'resourceTypeName'
                }
              }
              {
                source: {
                  name: 'resourceTypeGuid'
                  type: 'String'
                }
                sink: {
                  name: 'resourceTypeGuid'
                }
              }
              {
                source: {
                  name: 'offerId'
                  type: 'String'
                }
                sink: {
                  name: 'offerId'
                }
              }
              {
                source: {
                  name: 'resourceGroupName'
                  type: 'String'
                }
                sink: {
                  name: 'resourceGroupName'
                }
              }
            ]
          }
        }
        inputs: [
          {
            referenceName: 'UsageDetailsAggregatedBlob'
            type: 'DatasetReference'
            parameters: {
            }
          }
        ]
        outputs: [
          {
            referenceName: 'UsageDetailsDestinationTable'
            type: 'DatasetReference'
            parameters: {
            }
          }
        ]
      }
    ]
    annotations: []
  }
  dependsOn: [
    dataFactoryDatasetUsageDetailsApiResponseRes
    dataFactoryDatasetUsageDetailsRawBlobRes
    dataFactoryDatasetUsageDetailsAggregatedBlobRes
    dataFactoryDatasetUsageDetailsDestinationTableRes
    dataFactoryDataflowAggregateUsageDetailsRes
  ]
}

resource dataFactoryLinkedSvcAzureManagementApiRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'AzureManagementApi'
  properties: {
    annotations: []
    type: 'RestService'
    typeProperties: {
      url: '${environment().resourceManager}subscriptions/${subscription().id}/providers/Microsoft.Consumption/usageDetails'
      enableServerCertificateValidation: true
      authenticationType: 'AadServicePrincipal'
      servicePrincipalId: analyticsServicePrincipalId
      servicePrincipalKey: {
        type: 'AzureKeyVaultSecret'
        store: {
          referenceName: 'AzureKeyVault'
          type: 'LinkedServiceReference'
        }
        secretName: keyVaultSecretAnalyticsServicePrincipalSecret
      }
      tenant: subscription().tenantId
      #disable-next-line use-resource-id-functions
      aadResourceId: environment().resourceManager
    }
  }
  dependsOn: [
    keyVaultSecretsFromArrayRes
  ]
}

resource dataFactoryLinkedSvcCostDataBlobStorageRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'CostDataBlobStorage'
  properties: {
    annotations: []
    type: 'AzureBlobStorage'
    typeProperties: {
      connectionString: {
        type: 'AzureKeyVaultSecret'
        store: {
          referenceName: 'AzureKeyVault'
          type: 'LinkedServiceReference'
        }
        secretName: keyVaultSecretStorageAccountConnectionString
      }
    }
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
  ]
}

resource dataFactoryLinkedSvcUsageDetailsTableStorageRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'UsageDetailsTableStorage'
  properties: {
    annotations: []
    type: 'AzureTableStorage'
    typeProperties: {
      connectionString: {
        type: 'AzureKeyVaultSecret'
        store: {
          referenceName: 'AzureKeyVault'
          type: 'LinkedServiceReference'
        }
        secretName: keyVaultSecretStorageAccountConnectionString
      }
    }
  }
  dependsOn: [
    keyVaultSecretStorageAccountConnectionStringRes
  ]
}

resource dataFactoryDatasetUsageDetailsDestinationTableRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'UsageDetailsDestinationTable'
  properties: {
    linkedServiceName: {
      referenceName: 'UsageDetailsTableStorage'
      type: 'LinkedServiceReference'
    }
    parameters: {
      UsageDetailsTableName: {
        type: 'String'
        defaultValue: 'usagedetails'
      }
    }
    folder: {
      name: 'UsageDetails'
    }
    annotations: []
    type: 'AzureTable'
    schema: []
    typeProperties: {
      tableName: {
        value: '@dataset().UsageDetailsTableName'
        type: 'Expression'
      }
    }
  }
  dependsOn: [
    dataFactoryLinkedSvcUsageDetailsTableStorageRes
  ]
}

resource dataFactoryDatasetUsageDetailsAggregatedBlobRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'UsageDetailsAggregatedBlob'
  properties: {
    linkedServiceName: {
      referenceName: 'CostDataBlobStorage'
      type: 'LinkedServiceReference'
    }
    parameters: {
      UsageDetailsExportContainer: {
        type: 'String'
        defaultValue: 'exports'
      }
    }
    folder: {
      name: 'UsageDetails'
    }
    annotations: []
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: {
          value: '@dataset().UsageDetailsExportContainer'
          type: 'Expression'
        }
      }
      columnDelimiter: ','
      escapeChar: '\\'
      firstRowAsHeader: true
      quoteChar: '"'
    }
    schema: [
      {
        name: 'partitionKey'
        type: 'String'
      }
      {
        name: 'date'
        type: 'String'
      }
      {
        name: 'usageQuantity'
        type: 'String'
      }
      {
        name: 'pretaxCost'
        type: 'String'
      }
      {
        name: 'id'
        type: 'String'
      }
      {
        name: 'resourceId'
        type: 'String'
      }
      {
        name: 'resourceName'
        type: 'String'
      }
      {
        name: 'location'
        type: 'String'
      }
      {
        name: 'meterId'
        type: 'String'
      }
      {
        name: 'currency'
        type: 'String'
      }
      {
        name: 'isEstimated'
        type: 'String'
      }
      {
        name: 'subscriptionGuid'
        type: 'String'
      }
      {
        name: 'resourceTypeName'
        type: 'String'
      }
      {
        name: 'resourceTypeGuid'
        type: 'String'
      }
      {
        name: 'offerId'
        type: 'String'
      }
      {
        name: 'resourceGroupName'
        type: 'String'
      }
    ]
  }
  dependsOn: [
    dataFactoryLinkedSvcCostDataBlobStorageRes
  ]
}

resource dataFactoryDatasetUsageDetailsRawBlobRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'UsageDetailsRawBlob'
  properties: {
    linkedServiceName: {
      referenceName: 'CostDataBlobStorage'
      type: 'LinkedServiceReference'
    }
    parameters: {
      UsageDetailsExportContainer: {
        type: 'String'
        defaultValue: 'exports'
      }
      UsageDetailsRawBlobName: {
        type: 'String'
        defaultValue: 'usage-details.json'
      }
    }
    folder: {
      name: 'UsageDetails'
    }
    annotations: []
    type: 'Json'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        fileName: {
          value: '@dataset().UsageDetailsRawBlobName'
          type: 'Expression'
        }
        container: {
          value: '@dataset().UsageDetailsExportContainer'
          type: 'Expression'
        }
      }
    }
    schema: {
      type: 'object'
      properties: {
        id: {
          type: 'string'
        }
        date: {
          type: 'string'
        }
        resourceId: {
          type: 'string'
        }
        resourceName: {
          type: 'string'
        }
        location: {
          type: 'string'
        }
        meterId: {
          type: 'string'
        }
        usageQuantity: {
          type: 'number'
        }
        pretaxCost: {
          type: 'number'
        }
        currency: {
          type: 'string'
        }
        isEstimated: {
          type: 'boolean'
        }
        subscriptionGuid: {
          type: 'string'
        }
        resourceTypeName: {
          type: 'string'
        }
        resourceTypeGuid: {
          type: 'string'
        }
        offerId: {
          type: 'string'
        }
      }
    }
  }
  dependsOn: [
    dataFactoryLinkedSvcCostDataBlobStorageRes
  ]
}

resource dataFactoryDatasetUsageDetailsApiResponseRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'UsageDetailsApiResponse'
  properties: {
    linkedServiceName: {
      referenceName: 'AzureManagementApi'
      type: 'LinkedServiceReference'
    }
    folder: {
      name: 'UsageDetails'
    }
    annotations: []
    type: 'RestResource'
    typeProperties: {
      relativeUrl: '?api-version=2019-01-01'
    }
    schema: []
  }
  dependsOn: [
    dataFactoryLinkedSvcAzureManagementApiRes
  ]
}

resource dataFactoryDataflowAggregateUsageDetailsRes 'Microsoft.DataFactory/factories/dataflows@2018-06-01' = {
  parent: dataFactoryRes
  name: 'AggregateUsageDetails'
  properties: {
    type: 'MappingDataFlow'
    typeProperties: {
      sources: [
        {
          dataset: {
            referenceName: 'UsageDetailsRawBlob'
            type: 'DatasetReference'
          }
          name: 'blobData'
        }
      ]
      sinks: [
        {
          dataset: {
            referenceName: 'UsageDetailsAggregatedBlob'
            type: 'DatasetReference'
          }
          name: 'tableData'
        }
      ]
      transformations: [
        {
          name: 'aggregatedData'
        }
        {
          name: 'mappedData'
          description: 'Creates an explicit mapping for each drifted column'
        }
      ]
      script: 'source(output(\n\t\tid as string,\n\t\tdate as string,\n\t\tresourceId as string,\n\t\tresourceName as string,\n\t\tlocation as string,\n\t\tmeterId as string,\n\t\tusageQuantity as double,\n\t\tpretaxCost as double,\n\t\tcurrency as string,\n\t\tisEstimated as boolean,\n\t\tsubscriptionGuid as string,\n\t\tresourceTypeName as string,\n\t\tresourceTypeGuid as string,\n\t\tofferId as string\n\t),\n\tallowSchemaDrift: false,\n\tvalidateSchema: false,\n\twildcardPaths:[\'usage-details.json\']) ~> blobData\nmappedData aggregate(groupBy(partitionKey,\n\t\tdate),\n\tusageQuantity = sum(usageQuantity),\n\t\tpretaxCost = sum(pretaxCost),\n\t\teach(match(!in([\'partitionKey\',\'date\',\'usageQuantity\',\'pretaxCost\'],name)), $$ = first($$))) ~> aggregatedData\nblobData derive(id = lower(toString(byName(\'id\'))),\n\t\tdate = toString(byName(\'date\')),\n\t\tresourceId = toString(byName(\'resourceId\')),\n\t\tresourceName = lower(toString(byName(\'resourceName\'))),\n\t\tlocation = toString(byName(\'location\')),\n\t\tmeterId = lower(toString(byName(\'meterId\'))),\n\t\tusageQuantity = toDouble(byName(\'usageQuantity\')),\n\t\tpretaxCost = toDouble(byName(\'pretaxCost\')),\n\t\tcurrency = toString(byName(\'currency\')),\n\t\tisEstimated = toBoolean(byName(\'isEstimated\')),\n\t\tsubscriptionGuid = lower(toString(byName(\'subscriptionGuid\'))),\n\t\tresourceTypeName = toString(byName(\'resourceTypeName\')),\n\t\tresourceTypeGuid = lower(toString(byName(\'resourceTypeGuid\'))),\n\t\tofferId = toString(byName(\'offerId\')),\n\t\tresourceGroupName = lower(regexExtract(byName(\'resourceId\'), \'\\\\/(?i)resourceGroups\\\\/(.*?)\\\\/\', 1)),\n\t\tpartitionKey = lower(concat(byName(\'resourceName\'), \':\', byName(\'meterId\')))) ~> mappedData\naggregatedData sink(input(\n\t\tpartitionKey as string,\n\t\tdate as string,\n\t\tusageQuantity as string,\n\t\tpretaxCost as string,\n\t\tid as string,\n\t\tresourceId as string,\n\t\tresourceName as string,\n\t\tlocation as string,\n\t\tmeterId as string,\n\t\tcurrency as string,\n\t\tisEstimated as string,\n\t\tsubscriptionGuid as string,\n\t\tresourceTypeName as string,\n\t\tresourceTypeGuid as string,\n\t\tofferId as string,\n\t\tresourceGroupName as string\n\t),\n\tallowSchemaDrift: true,\n\tvalidateSchema: false,\n\tpartitionFileNames:[\'usage-details.csv\'],\n\tpartitionBy(\'hash\', 1),\n\tskipDuplicateMapInputs: true,\n\tskipDuplicateMapOutputs: true) ~> tableData'
    }
  }
  dependsOn: [
    dataFactoryDatasetUsageDetailsRawBlobRes
    dataFactoryDatasetUsageDetailsAggregatedBlobRes
  ]
}
