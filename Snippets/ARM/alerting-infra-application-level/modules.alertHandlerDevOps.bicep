@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param devOpsOrgName string
param devOpsProjectName string
param devOpsWorkItemType string = 'Bug'
@description('Depends on the DevOps project type (Scrum, Agile, Basic, ...)')
param devOpsWorkItemBaseType string = 'Product Backlog Item'

param addNotificationForOwnersAndContributors bool = true

var azDevOpsConnectionName = '${resourceNamePrefix}-devops-con-${resourceNameSuffix}'
var azMgmtUrlWithoutSlash = endsWith(environment().resourceManager, '/') ? take(environment().resourceManager, length(environment().resourceManager)-1) : environment().resourceManager

var logicAppDevOpsHandlerName  = '${resourceNamePrefix}-devops-la-${resourceNameSuffix}'

var actionGrpDevOpsHandlerName  = '${resourceNamePrefix}-devops-ag-${resourceNameSuffix}'
var actionGrpDevOpsHandlerShortName = 'DevOps'

resource azDevOpsConnectionRes 'Microsoft.Web/connections@2016-06-01' = {
  name: azDevOpsConnectionName
  location: resourceLocation
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', resourceLocation, 'visualstudioteamservices')
    }
    testLinks: [
      {
        requestUri: '${azMgmtUrlWithoutSlash}:443${resourceGroup().id}/providers/Microsoft.Web/connections/visualstudioteamservices/extensions/proxy/_apis/Accounts?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

resource actionGrpDevOpsHandlerRes 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGrpDevOpsHandlerName
  location: 'Global'
  properties: {
    groupShortName: actionGrpDevOpsHandlerShortName // Caution: maximal 12 characters
    enabled: true
    emailReceivers: []
    smsReceivers: []
    webhookReceivers: []
    eventHubReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: [
      {
        name: actionGrpDevOpsHandlerShortName
        resourceId: logicAppDevOpsHandlerRes.id
        callbackUrl: logicAppDevOpsHandlerRes.listCallbackUrl().value
        useCommonAlertSchema: true
      }
    ]
    azureFunctionReceivers: []
    armRoleReceivers: addNotificationForOwnersAndContributors ? [
      // Overview of built-in roles with its IDs: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
      {
        name: 'Owner'
        roleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
        useCommonAlertSchema: true
      }
      {
          name: 'Contributor'
          roleId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
          useCommonAlertSchema: true
      }
    ] : []
  }
}

resource logicAppDevOpsHandlerRes 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppDevOpsHandlerName
  location: resourceLocation
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
        DevOpsOrgName: {
          defaultValue: devOpsOrgName
          type: 'String'
        }
        DevOpsProjectName: {
          defaultValue: devOpsProjectName
          type: 'String'
        }
        DevOpsWorkItemType: {
          defaultValue: devOpsWorkItemType
          type: 'String'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                data: {
                  properties: {
                    alertContext: {
                      properties: {
                        condition: {
                          properties: {
                            allOf: {
                              items: {
                                properties: {
                                  dimensions: {
                                    type: 'array'
                                  }
                                  metricName: {
                                    type: 'string'
                                  }
                                  metricNamespace: {
                                    type: 'string'
                                  }
                                  metricValue: {
                                    type: 'integer'
                                  }
                                  operator: {
                                    type: 'string'
                                  }
                                  threshold: {
                                    type: 'string'
                                  }
                                  timeAggregation: {
                                    type: 'string'
                                  }
                                  webTestName: {
                                  }
                                }
                                required: [
                                  'metricName'
                                  'metricNamespace'
                                  'operator'
                                  'threshold'
                                  'timeAggregation'
                                  'dimensions'
                                  'metricValue'
                                  'webTestName'
                                ]
                                type: 'object'
                              }
                              type: 'array'
                            }
                            windowEndTime: {
                              type: 'string'
                            }
                            windowSize: {
                              type: 'string'
                            }
                            windowStartTime: {
                              type: 'string'
                            }
                          }
                          type: 'object'
                        }
                        conditionType: {
                          type: 'string'
                        }
                        properties: {
                          properties: {
                            programmerLocation: {
                              type: 'string'
                            }
                          }
                          type: 'object'
                        }
                      }
                      type: 'object'
                    }
                    customProperties: {
                      properties: {
                        ProgrammerLocation: {
                          type: 'string'
                        }
                      }
                      type: 'object'
                    }
                    essentials: {
                      properties: {
                        alertContextVersion: {
                          type: 'string'
                        }
                        alertId: {
                          type: 'string'
                        }
                        alertRule: {
                          type: 'string'
                        }
                        alertTargetIDs: {
                          items: {
                            type: 'string'
                          }
                          type: 'array'
                        }
                        configurationItems: {
                          items: {
                            type: 'string'
                          }
                          type: 'array'
                        }
                        description: {
                          type: 'string'
                        }
                        essentialsVersion: {
                          type: 'string'
                        }
                        firedDateTime: {
                          type: 'string'
                        }
                        monitorCondition: {
                          type: 'string'
                        }
                        monitoringService: {
                          type: 'string'
                        }
                        originAlertId: {
                          type: 'string'
                        }
                        severity: {
                          type: 'string'
                        }
                        signalType: {
                          type: 'string'
                        }
                      }
                      type: 'object'
                    }
                  }
                  type: 'object'
                }
                schemaId: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Create_a_work_item: {
          runAfter: {
            Generate_Link: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              description: '<p>Description: @{triggerBody()?[\'data\']?[\'essentials\']?[\'description\']}<br>\nTimestamp: @{triggerBody()?[\'data\']?[\'essentials\']?[\'firedDateTime\']}<br>\nAzure Resources: @{body(\'Generate_ResourceInfo\')}<br>\nSeverity: @{triggerBody()?[\'data\']?[\'essentials\']?[\'severity\']}<br>\nLink: @{concat(\'<a href="\', outputs(\'Generate_Link\'), \'" target="_blank">View in Azure Portal</a>\')}<br>\n----------------------------------<br>\n@{triggerBody()}</p>'
              title: 'Analyze Alert: @{triggerBody()?[\'data\']?[\'essentials\']?[\'alertRule\']}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'visualstudioteamservices\'][\'connectionId\']'
              }
            }
            method: 'patch'
            path: '/@{encodeURIComponent(\'${devOpsProjectName}\')}/_apis/wit/workitems/$@{encodeURIComponent(\'${devOpsWorkItemBaseType}\')}'
            queries: {
              account: devOpsOrgName
            }
          }
        }
        Generate_Link: {
          runAfter: {
            Generate_ResourceInfo: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '@concat(\'https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AlertDetailsTemplateBlade/alertId/\', replace(triggerBody()?[\'data\']?[\'essentials\']?[\'alertId\'], \'/\', \'%2F\'), \'/invokedFrom/emailcommonschema\')'
        }
        Generate_ResourceInfo: {
          runAfter: {
          }
          type: 'Join'
          inputs: {
            from: '@triggerBody()?[\'data\']?[\'essentials\']?[\'configurationItems\']'
            joinWith: ','
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          visualstudioteamservices: {
            connectionId: azDevOpsConnectionRes.id
            connectionName: 'visualstudioteamservices'
            id: '${subscription().id}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/visualstudioteamservices'
          }
        }
      }
    }
  }
}

output actionGrpResId string = actionGrpDevOpsHandlerRes.id
