# C# Code snippets
General resources:
* [Kusto Query Language Reference](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/)
* [Demo Space](https://portal.loganalytics.io/demo#/discover/query/main)

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

## Contents
| Service(s)                      | Architecture                | Problem / Solution                      | Related | Link                            |
|---------------------------------|-----------------------------|-----------------------------------------|---------|---------------------------------|
| API Management | - | List all failed request details for analytics | - | [ApiManagementFailedRequestDetails](./ApiManagementFailedRequestDetails.txt) |
| Application Insights | - | List all custom metrics for analytics. [See here for how to generate custom metrics in functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-monitoring?tabs=cmd#custom-metrics-logging) | - | [ApplicationInsightsCustomMetrics](./ApplicationInsightsCustomMetrics.txt) |
| Application Insights | - | Get Function execution details (including duration) for analytics | - | [ApplicationInsightsFunctionExecutions](./ApplicationInsightsFunctionExecutions.txt) |
| Data Factory | - | Get Pipeline execution details (including duration) for analytics | - | [DataFactoryPipelineExecutions](./DataFactoryPipelineExecutions.txt) |
| Resource Group | - | List all deployments in a particular resource group. **Important**: To have this data available, you need to [connect Azure Activity Log to the according Log Analytics Workspace](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log#log-analytics-workspace). | [activity-log-link-log-analytics-workspace](../ARM/activity-log-link-log-analytics-workspace) | [DeploymentsInResourceGroup](./DeploymentsInResourceGroup.txt) |
