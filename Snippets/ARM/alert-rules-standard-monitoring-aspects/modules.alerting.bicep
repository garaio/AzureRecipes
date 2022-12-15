@description('The prefix will be used for every parameter that represents a resource name')
param resourceNamePrefix string

@description('The suffix will be appended to every parameter that represents a resource name')
param resourceNameSuffix string

param resourceLocation string = resourceGroup().location

param appInsightsResId string
param apiManagementResId string
param dataFactoryResId string
param logicAppResId string
param sqlDatabaseResId string
param cosmosDbAccountResId string
param serviceBusResId string

param actionGrpOrgOpsIndicationsResId string
param actionGrpOrgOpsIssuesResId string
param actionGrpAppDevOpsTeamResId string

param enableAlertRules bool = true

// [Standard] To be deployed for each (relevant) instance of Application Insights (caution: naming conflicts - encapsulate in Resource Group)
module alertRulesTechnicalRequestErrorsRes './modules.alertRulesTechnicalRequestErrors.bicep' = if(!empty(appInsightsResId)) {
  name: 'alert-rules-techreqerr'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceLocation: resourceLocation
    appInsightsResId: appInsightsResId
    actionGroupResId: actionGrpAppDevOpsTeamResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Application Insights (caution: naming conflicts - encapsulate in Resource Group)
module alertRulesRequestsQualityRes './modules.alertRulesRequestsQuality.bicep' = if(!empty(appInsightsResId)) {
  name: 'alert-rules-reqquality'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceLocation: resourceLocation
    appInsightsResId: appInsightsResId
    actionGroupResId: actionGrpOrgOpsIndicationsResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Application Insights (caution: naming conflicts - encapsulate in Resource Group)
module alertRulesFunctionsDurationRes './modules.alertRulesFunctionAppDuration.bicep' = if(!empty(appInsightsResId)) {
  name: 'alert-rules-funcdur'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceLocation: resourceLocation
    appInsightsResId: appInsightsResId
    actionGroupResId: actionGrpAppDevOpsTeamResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Application Insights (caution: naming conflicts - encapsulate in Resource Group)
module alertRulesSmartDetectionRes './modules.alertRulesSmartDetection.bicep' = if(!empty(appInsightsResId)) {
  name: 'alert-rules-smartdetect'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceLocation: resourceLocation
    appInsightsResId: appInsightsResId
    actionGroupResId: actionGrpOrgOpsIndicationsResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of API Management
module alertRulesApiManagementCapacityRes './modules.alertRulesApiManagementCapacity.bicep' = if(!empty(apiManagementResId)) {
  name: 'alert-rules-apimcap'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    apiManagementResId: apiManagementResId
    actionGroupResId: actionGrpOrgOpsIndicationsResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Data Factory
module alertRulesDataFactoryExecutionsRes './modules.alertRulesDataFactoryExecutions.bicep' = if(!empty(dataFactoryResId)) {
  name: 'alert-rules-dfpfails'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    dataFactoryResId: dataFactoryResId
    actionGroupResId: actionGrpOrgOpsIssuesResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Logic App
module alertRulesLogicAppExecutionsRes './modules.alertRulesLogicAppExecutions.bicep' = if(!empty(logicAppResId)) {
  name: 'alert-rules-laexec'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    logicAppResId: logicAppResId
    actionGroupResId: actionGrpOrgOpsIssuesResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of SQL Database in DTU-based SKU
module alertRulesSqlDatabaseCapacityRes './modules.alertRulesSqlDbDtuPercentage.bicep' = if(!empty(sqlDatabaseResId)) {
  name: 'alert-rules-sqldbcap'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    sqlDatabaseResId: sqlDatabaseResId
    actionGroupResId: actionGrpOrgOpsIssuesResId    
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Cosmos DB in Manual/Provisioned Throughput Model
module alertRulesCosmosDbRuPercentageRes './modules.alertRulesCosmosDbRuPercentage.bicep' = if(!empty(cosmosDbAccountResId)) {
  name: 'alert-rules-cosmosdbcap'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    cosmosDbAccountResId: cosmosDbAccountResId
    actionGroupResId: actionGrpOrgOpsIssuesResId    
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed for each (relevant) instance of Service Bus that may use dead-letter queueing
module alertRulesServiceBusDeadLetterQueueRes './modules.alertRulesServiceBusDeadLetterQueue.bicep' = if(!empty(serviceBusResId)) {
  name: 'alert-rules-sbdlq'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    serviceBusResId: serviceBusResId
    actionGroupResId: actionGrpOrgOpsIssuesResId    
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed per Resource Group (difference to Service Health alerts = these are for concrete outages)
module alertRulesResourceHealthRes './modules.alertRulesResourceHealth.bicep' = {
  name: 'alert-rules-reshealth'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    subscriptionId: subscription().id
    resourceGroupName: resourceGroup().name
    actionGroupResId: actionGrpOrgOpsIssuesResId
    enableAlertRules: enableAlertRules
  }
}

// [Standard] To be deployed per Resource Group
module alertRulesActivityLogRes './modules.alertRulesActivityLog.bicep' = {
  name: 'alert-rules-activitylog'
  scope: resourceGroup()
  params: {
    resourceNamePrefix: resourceNamePrefix
    resourceNameSuffix: resourceNameSuffix
    resourceGroupId: resourceGroup().id
    actionGroupResId: actionGrpOrgOpsIndicationsResId
    enableAlertRules: enableAlertRules
  }
}

// [Customized] Application Insights Availability Tests: To be deployed per relevant endpoint
// (placeholder)

// [Custom] Specific Alert Rules for application
// (placeholder)
