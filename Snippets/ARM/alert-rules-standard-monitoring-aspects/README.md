# Alert Rules for Standard Monitoring Aspects

This snippet provides the implementation of the typical key aspects of often used Azure PaaS resources, as [explained and documented in this "Best Practices" post](../../../Knowledge/BestPractices-AzureSolutions-Monitoring).

## Dependencies / Setup

The Action Group(s) must be created in advance and its resource identifier specified as parameter. Therefore, an alerting strategy should exist, which defines responsibilities and required notification flows. This snippet correlates with this [Alerting Strategy Template](../../../Templates/Guideline-AlertingStrategy) and plays well with following setup:

> Action Groups on organisation level (shared for all applications): _coming soon_

> Action Group(s) and DevOps Handler/Connector on application level (but common for all modules and independent from environments): _coming soon_

## Contents

### Bicep Module including all Alert Rules

For consistency it is recommended to use this Bicep module in projects. Resource-specific alert rules are deployed only when according parameter is correctly specified.

> [Full Alerting Setup](./modules.alerting.bicep)

### Single Alert Rule definitions

The referenced Bicep modules group Alert Rules by resource type and use case. All of them can also be directly used and cherry-picked.

#### Security & Documentation:
* [Activity Log: Role Assignments applicable to Resource Group](./modules.alertRulesActivityLog.bicep)

#### Operational Indications:
* [Activity Log: A resource in the Resource Group is impacted by a platform-related outage or degregation](./modules.alertRulesResourceHealth.bicep)
* [API Management: Used capacity exceeding treshold (scaling needs)](./modules.alertRulesApiManagementCapacity.bicep)
* [Cosmos DB: Used capacity (in provisioned throughput model) exceeding treshold (scaling needs)](./modules.alertRulesCosmosDbRuPercentage.bicep)
* [SQL Database: Used capacity (in DTU model) exceeding treshold (scaling needs)](./modules.alertRulesSqlDbDtuPercentage.bicep)

#### Operational Incidents (concrete failures or outages):
* [Data Factory: Pipelines execution failures](./modules.alertRulesDataFactoryExecutions.bicep)
* [Logic App: Either error-rate exceeds treshold or on single execution failures](./modules.alertRulesLogicAppExecutions.bicep)
* [Service Bus: A message has been appended to dead-letter queue (because regular processing failed)](./modules.alertRulesServiceBusDeadLetterQueue.bicep)

#### Technical Warnings (development-related):
* [Application Insights: Migration of default Smart Detection to regular Alert Rules](./modules.alertRulesSmartDetection.bicep)
* [Application Insights (Function Apps): Execution duration reaches configured treshold (avoid failures when running into technical timeout)](./modules.alertRulesFunctionAppDuration.bicep)
* [Application Insights (App Services: Error rate of requests exceeds treshold (SLA may be impacted)](./modules.alertRulesRequestsQuality.bicep)
* [Application Insights (App Services): Unhandled server-side error occured during request execution (leading to HTTP 5xx results)](./modules.alertRulesTechnicalRequestErrors.bicep)
