# Azure Resource Manager Templates
General resources:
* [Schema Definition Reference](https://docs.microsoft.com/en-us/azure/templates)
* [ARM Visualizer](http://armviz.io/designer)

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

## Contents
| Service(s) | Level | Architecture | Problem / Solution | Related | Link |
|---------------------------------|---------------------------------|-----------------------------|-----------------------------------------|---------|---------------------------------|
| App Service (Function, Web App) | Resource Group | API for Client applications | Enforcing AAD-based user authentication | - | [function-aad-authentication](./function-aad-authentication) |
| CDN | Resource Group | SPA | Provide SPA with CDN | - | [setup-CDN-with-rule-for-SPA](./setup-CDN-with-rule-for-SPA) |
| Activity Log | Subscription | - | Link Activity Log with Log Analytics Workspace for external analytics | - | [activity-log-link-log-analytics-workspace](./activity-log-link-log-analytics-workspace) |
| Resource Group | Subscription | - | Create Resource Group with Storage Account for deployment artefact | - | [prepare-resource-group-for-deployment](./prepare-resource-group-for-deployment) |
| App Service (Function, Web App) | Resource Group | - | Complete setup of ZIP-deployment to Storage Account. Includes Key Vault based settings and Application Insights | - | [function-run-from-package-in-storage-account](./function-run-from-package-in-storage-account) |
| API Management, App Service (Function, Web App) | Resource Group | - | Complete setup of API Management for a Function including Open API schema definitions and injection of authentication key | - | [function-api-management](./function-api-management) |
| Data Factory | Resource Group | - | Backup all existing Storage Tables as CSV into Blob Storage & Restore manually placed CSV-files of specific Blob Container to according Storage Table | - | [data-factory-backup-restore-storage-tables](./data-factory-backup-restore-storage-tables) |
| Data Factory | Resource Group | - | Ingest all usage details of current subscription to a Storage Table (ready for direct visualisation) | - | [data-factory-usage-details-ingestion](./data-factory-usage-details-ingestion) |
| Alert Rule | Resource Group | - | Alert on manual changes to resources in Resource Group. **Important**: To have this data available, you need to [connect Azure Activity Log to the according Log Analytics Workspace](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/activity-log#log-analytics-workspace). | [activity-log-link-log-analytics-workspace](./activity-log-link-log-analytics-workspace) | [alert-rule-tampering](./alert-rule-tampering) |
| Alert Rule | Resource Group | - | Alert on non handled internal server errors (HTTP 500) in any resource connected to particular Application Insights | - | [alert-rule-http500](./alert-rule-http500) |
