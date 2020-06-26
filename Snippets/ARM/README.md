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
