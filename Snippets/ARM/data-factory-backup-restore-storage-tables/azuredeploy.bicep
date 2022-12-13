@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string = 'customer-project'

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

var logAnalyticsWsName = '${resourceNamePrefix}-law-${resourceNameSuffix}'
var dataFactoryName = '${resourceNamePrefix}-df-${resourceNameSuffix}'

var keyVaultName = '${resourceNamePrefix}-kv-${resourceNameSuffix}'
var keyVaultSecretStorageAccountConnectionString = 'storageAccountConnectionString'
var keyVaultSecretStorageAccountTablesSasToken = 'storageAccountTablesSasToken'

var storageAccountName = replace('${resourceNamePrefix}-sa-${resourceNameSuffix}', '-', '')
var storageAccountListTablesSasParams = {
  signedServices: 't'
  signedResourceTypes: 'c'
  signedPermission: 'l'
  signedExpiry: '2050-01-01T00:00:00Z'
}
var storageAccountTableUri = 'https://${storageAccountName}.table.${environment().suffixes.storage}'

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

resource keyVaultSecretStorageAccountConnectionStringRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountRes.id, '2019-06-01').keys[0].value}'
  }
}

resource keyVaultSecretStorageAccountTablesSasTokenRes 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultRes
  name: keyVaultSecretStorageAccountTablesSasToken
  properties: {
    value: listAccountSas(storageAccountRes.id, '2019-06-01', storageAccountListTablesSasParams).accountSasToken
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

resource dataFactoryPipelineBackupStorageTablesRes 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactoryRes
  name: 'BackupStorageTables'
  properties: {
    activities: [
      {
        name: 'ListExistingTables'
        type: 'Lookup'
        dependsOn: [
          {
            activity: 'GetKeyVaultSecret'
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
          secureInput: true
        }
        userProperties: []
        typeProperties: {
          source: {
            type: 'JsonSource'
            storeSettings: {
              type: 'HttpReadSettings'
              requestMethod: 'GET'
              additionalHeaders: 'Accept: application/json;odata=nometadata'
              requestTimeout: ''
            }
            formatSettings: {
              type: 'JsonReadSettings'
            }
          }
          dataset: {
            referenceName: 'StorageTablesApiResponse'
            type: 'DatasetReference'
            parameters: {
              StorageAccountSasToken: {
                value: '@activity(\'GetKeyVaultSecret\').output.value'
                type: 'Expression'
              }
            }
          }
          firstRowOnly: false
        }
      }
      {
        name: 'GetKeyVaultSecret'
        type: 'WebActivity'
        dependsOn: []
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: true
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          url: {
            value: '@concat(pipeline().parameters.KeyVaultSecretUri, \'?api-version=7.0\')'
            type: 'Expression'
          }
          method: 'GET'
          headers: {
          }
          authentication: {
            type: 'MSI'
            resource: 'https://${environment().suffixes.keyvaultDns}'
          }
        }
      }
      {
        name: 'SetTables'
        type: 'SetVariable'
        dependsOn: [
          {
            activity: 'ListExistingTables'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          variableName: 'Tables'
          value: {
            value: '@first(activity(\'ListExistingTables\').output.value).value'
            type: 'Expression'
          }
        }
      }
      {
        name: 'CreateDumpForTable'
        type: 'ForEach'
        dependsOn: [
          {
            activity: 'SetTables'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@variables(\'Tables\')'
            type: 'Expression'
          }
          activities: [
            {
              name: 'FilterIgnoredTables'
              type: 'IfCondition'
              dependsOn: []
              userProperties: []
              typeProperties: {
                expression: {
                  value: '@not(contains(pipeline().parameters.IgnoredTables, item().TableName))'
                  type: 'Expression'
                }
                ifTrueActivities: [
                  {
                    name: 'CreateDump'
                    type: 'Copy'
                    dependsOn: []
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
                        type: 'AzureTableSource'
                        azureTableSourceIgnoreTableNotFound: false
                      }
                      sink: {
                        type: 'DelimitedTextSink'
                        storeSettings: {
                          type: 'AzureBlobStorageWriteSettings'
                        }
                        formatSettings: {
                          type: 'DelimitedTextWriteSettings'
                          quoteAllText: true
                          fileExtension: '.csv'
                        }
                      }
                      enableStaging: false
                    }
                    inputs: [
                      {
                        referenceName: 'RecoveryTargetTable'
                        type: 'DatasetReference'
                        parameters: {
                          TableName: {
                            value: '@item().TableName'
                            type: 'Expression'
                          }
                        }
                      }
                    ]
                    outputs: [
                      {
                        referenceName: 'StorageTablesBackupBlob'
                        type: 'DatasetReference'
                        parameters: {
                          BackupBlobContainer: 'backup'
                          BackupTableName: {
                            value: '@item().TableName'
                            type: 'Expression'
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      }
    ]
    parameters: {
      KeyVaultSecretUri: {
        type: 'String'
        defaultValue: keyVaultSecretStorageAccountTablesSasTokenRes.properties.secretUri
      }
      IgnoredTables: {
        type: 'array'
        defaultValue: [
          'vnbdata'
        ]
      }
    }
    variables: {
      Tables: {
        type: 'Array'
      }
    }
    annotations: []
  }
  dependsOn: [

    dataFactoryDatasetStorageTablesApiResponseRes
    dataFactoryDatasetRecoveryTargetTableRes
    dataFactoryDatasetStorageTablesBackupBlobRes
  ]
}

resource dataFactoryPipelineRestoreStorageTableRes 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactoryRes
  name: 'RestoreStorageTable'
  properties: {
    activities: [
      {
        name: 'GetBlobMetadata'
        type: 'GetMetadata'
        dependsOn: []
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          dataset: {
            referenceName: 'StorageTablesRestoreBlob'
            type: 'DatasetReference'
            parameters: {
            }
          }
          fieldList: [
            'childItems'
          ]
          storeSettings: {
            type: 'AzureBlobStorageReadSettings'
          }
          formatSettings: {
            type: 'DelimitedTextReadSettings'
          }
        }
      }
      {
        name: 'RestoreSingleBlob'
        type: 'ForEach'
        dependsOn: [
          {
            activity: 'GetBlobMetadata'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@activity(\'GetBlobMetadata\').output.childItems'
            type: 'Expression'
          }
          activities: [
            {
              name: 'FilterEntityDumpBlob'
              type: 'IfCondition'
              dependsOn: []
              userProperties: []
              typeProperties: {
                expression: {
                  value: '@and(equals(length(split(item().name, \'-\')), 4), endswith(item().name, \'.csv\'))'
                  type: 'Expression'
                }
                ifTrueActivities: [
                  {
                    name: 'RestoreTableFromBlob'
                    type: 'Copy'
                    dependsOn: []
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
                          wildcardFileName: {
                            value: '@item().name'
                            type: 'Expression'
                          }
                          enablePartitionDiscovery: false
                        }
                        formatSettings: {
                          type: 'DelimitedTextReadSettings'
                        }
                      }
                      sink: {
                        type: 'AzureTableSink'
                        azureTableInsertType: 'replace'
                        azureTablePartitionKeyName: {
                          value: 'PartitionKey'
                          type: 'Expression'
                        }
                        azureTableRowKeyName: {
                          value: 'RowKey'
                          type: 'Expression'
                        }
                        writeBatchSize: 10000
                      }
                      enableStaging: false
                    }
                    inputs: [
                      {
                        referenceName: 'StorageTablesRestoreBlob'
                        type: 'DatasetReference'
                        parameters: {
                        }
                      }
                    ]
                    outputs: [
                      {
                        referenceName: 'RecoveryTargetTable'
                        type: 'DatasetReference'
                        parameters: {
                          TableName: {
                            value: '@first(split(item().name, \'-\'))'
                            type: 'Expression'
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      }
    ]
    annotations: []
  }
  dependsOn: [
    dataFactoryDatasetStorageTablesRestoreBlobRes
    dataFactoryDatasetRecoveryTargetTableRes
  ]
}

resource dataFactoryLinkedSvcRecoveryTargetTableStorageRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'RecoveryTargetTableStorage'
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

resource dataFactoryLinkedSvcStorageTablesRestoreBlobStorageRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'StorageTablesRestoreBlobStorage'
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

resource dataFactoryLinkedSvcStorageTablesBackupBlobStorageRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'StorageTablesBackupBlobStorage'
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

resource dataFactoryLinkedSvcStorageTablesApiRes 'Microsoft.DataFactory/factories/linkedServices@2018-06-01' = {
  parent: dataFactoryRes
  name: 'StorageTablesApi'
  properties: {
    annotations: []
    type: 'HttpServer'
    typeProperties: {
      url: storageAccountTableUri
      enableServerCertificateValidation: true
      authenticationType: 'Anonymous'
    }
  }
  dependsOn: []
}

resource dataFactoryDatasetRecoveryTargetTableRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'RecoveryTargetTable'
  properties: {
    linkedServiceName: {
      referenceName: 'RecoveryTargetTableStorage'
      type: 'LinkedServiceReference'
    }
    parameters: {
      TableName: {
        type: 'String'
        defaultValue: 'vnbdata'
      }
    }
    folder: {
      name: 'Recovery'
    }
    annotations: []
    type: 'AzureTable'
    schema: []
    typeProperties: {
      tableName: {
        value: '@dataset().TableName'
        type: 'Expression'
      }
    }
  }
  dependsOn: [
    dataFactoryLinkedSvcRecoveryTargetTableStorageRes
  ]
}

resource dataFactoryDatasetStorageTablesApiResponseRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'StorageTablesApiResponse'
  properties: {
    linkedServiceName: {
      referenceName: 'StorageTablesApi'
      type: 'LinkedServiceReference'
    }
    parameters: {
      StorageAccountSasToken: {
        type: 'string'
        defaultValue: 'sv=2019-10-10&ss=t&srt=sco&sp=rl&se=2025-06-16T19:47:37Z&st=2020-06-16T11:47:37Z&spr=https&sig=ABC'
      }
    }
    folder: {
      name: 'Recovery'
    }
    annotations: []
    type: 'Json'
    typeProperties: {
      location: {
        type: 'HttpServerLocation'
        relativeUrl: {
          value: '@concat(\'/tables?\', dataset().StorageAccountSasToken)'
          type: 'Expression'
        }
      }
    }
    schema: {
    }
  }
  dependsOn: [
    dataFactoryLinkedSvcStorageTablesApiRes
  ]
}

resource dataFactoryDatasetStorageTablesBackupBlobRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'StorageTablesBackupBlob'
  properties: {
    linkedServiceName: {
      referenceName: 'StorageTablesBackupBlobStorage'
      type: 'LinkedServiceReference'
    }
    parameters: {
      BackupBlobContainer: {
        type: 'String'
        defaultValue: 'backup'
      }
      BackupTableName: {
        type: 'String'
        defaultValue: 'table'
      }
    }
    folder: {
      name: 'Recovery'
    }
    annotations: []
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        fileName: {
          value: '@concat(dataset().BackupTableName, \'-\', utcnow(), \'.csv\')'
          type: 'Expression'
        }
        container: {
          value: '@dataset().BackupBlobContainer'
          type: 'Expression'
        }
      }
      columnDelimiter: ','
      escapeChar: '\\'
      firstRowAsHeader: true
      quoteChar: '"'
    }
    schema: []
  }
  dependsOn: [
    dataFactoryLinkedSvcStorageTablesBackupBlobStorageRes
  ]
}

resource dataFactoryDatasetStorageTablesRestoreBlobRes 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactoryRes
  name: 'StorageTablesRestoreBlob'
  properties: {
    linkedServiceName: {
      referenceName: 'StorageTablesRestoreBlobStorage'
      type: 'LinkedServiceReference'
    }
    folder: {
      name: 'Recovery'
    }
    annotations: []
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: 'restore'
      }
      columnDelimiter: ','
      escapeChar: '\\'
      firstRowAsHeader: true
      quoteChar: '"'
    }
    schema: []
  }
  dependsOn: [
    dataFactoryLinkedSvcStorageTablesRestoreBlobStorageRes
  ]
}
