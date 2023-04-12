[![Azure Recipes by GARAIO AG](./Resources/Logo.svg)](https://garaio.com)

# Azure Recipes
This repository contains various guidances and artefacts collected during engineering of applications on Microsoft Azure. Most of them are based on PaaS or serverless services.

- [Azure Recipes](#azure-recipes)
  - [Contents](#contents)
    - [Blueprints](#blueprints)
    - [Snippets](#snippets)
    - [Templates](#templates)
    - [Knowledge](#knowledge)
  - [Support](#support)
  - [License](#license)

## Contents
The content is focused to the type of applications GARAIO AG typically develops as well as the tools and toolchain typically used for that. This includes mainly following tools:
* Azure DevOps (Code and Release Management, Pipelines)
* Visual Studio / Visual Studio Core (Engineering)
* Power BI (Analytics)

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

### Blueprints
Some quickstart templates for projects with standardized architectures.

| Architecture | Purpose | Description | Link |
|--------------|---------|-------------|------|
| Serverless | General applications | Base resources including Storage Account, Log Analytics Workspace, Application Insights and Key Vault | [Show](./Blueprints/serverless-base-resources) |
| Integration Pipeline | Integration scenarios | Exchange and transform data between systems in a robust and asynchronous way, based on Service Bus, Logic Apps and Functions | [Show](./Blueprints/integration-pipeline) |
| Search Engine | Content-based solutions for customer or employees | Central, independent search engine that delivers results from multiple data sources and enriches them with intelligent suggestions | [Show](./Blueprints/search-engine) |
| SPA / API Application | UI applications for customer or employees | Single-page application (framework agnostic) consuming a REST API connected to a database, optionally including Active Directory based user authentication | [Show](./Blueprints/spa-api-application) |
| Bot Framework Application | Bots connected with enterprise systems for knowledge and processes | Bot Framework based App Service with Cognitive Services LUIS and QnA Maker, the latter being integrated with enterprise data sources | [Show](./Blueprints/virtual-agent) |
| Analytics Platform | Central BI infrastructure | Central Synapse Workspace efficently providing Power BI workspaces with pre-processed data | [Show](./Blueprints/analytics-platform) |
| Central API Management | Integration scenarios | Provide secure, observable and managed access to enterprise APIs of various application including Developer Portal for API definitions and testing | [Show](./Blueprints/central-api-management) |

### Snippets
Directly reusable code artefacts for development, deployment or monitoring / analytics grouped by type of language or format.

| Type | Description                           | Link             |
|------|---------------------------------------|------------------|
| ARM (Bicep)  | [Azure Resource Manager definitions](https://docs.microsoft.com/en-us/azure/templates/) for resource deployment | [Show](./Snippets/ARM) |
| CLI  | Azure Command Line Interface commands. This also includes queries based on [JMESPath](https://jmespath.org/) | [Show](./Snippets/CLI)  |
| csharp | Code snippets such as classes or methods for functionality e.g. in Functions. Class libraries are rather published via Nuget.  | [Show](./Snippets/csharp) |
| KQL  | [Kusto Query Language](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/) snippets used for analytics in various services such as Application Insights, Log Analytics Workspace or Data Explorer | [Show](./Snippets/KQL)  |
| Pipelines  | Azure DevOps pipelines or pipeline tasks in either YAML or JSON format | [Show](./Snippets/Pipelines)  |
| PowerQuery | [PowerQuery M](https://docs.microsoft.com/en-us/powerquery-m/) or DAX artefacts used in Power BI (or e.g. Data Factory wrangling data flows)  | [Show](./Snippets/PowerQuery) |
| Web | Mostly JavaScript-based or related code snippets used to interact with Azure Services  | [Show](./Snippets/Web) |

### Templates
This contains document structures and contents for technical reviews and project-specific definition of guidelines or conventions.

| Type | Scope | Description | Link |
|------|-------|-------------|------|
| Convention | Project Setup, Consulting | How to structure and name application components as code artefacts and Azure resources | [Show](./Templates/Convention-ResourceStructuringAndNaming.md) |
| Convention | Project Setup, Consulting | How to tag Azure resources for maintainability | [Show](./Templates/Convention-ResourceTagging.md) |
| Convention | Project Setup, Consulting | Recommended minimal set of policies for PaaS applications (ideally applied on Management Group) | [Show](./Templates/Convention-PolicyAssignments.md) |
| Structure | Cloud Strategy, Operations & Governance | Basic definition and framework for development and operation of IT applications on Azure, based on and adapted from the [Microsoft Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/operating-model). | [Show](./Templates/Structure-CloudOperatingModel) |
| Guideline | Cloud Migrations | Simple implementation of [the concept known from the Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/) giving guidelines to migrate or newly realise PaaS or CaaS applications | [Show](./Templates/Guideline-ApplicationLandingZones) |
| Miscellaneous | Cloud Migrations | Various templates for visualisation, planning and decision-making to support enterprise-level application migration (templates are mostly in German) | [Show](./Templates/Miscellaneous-CloudMigrationResources) |
| Review | Application Architecture & Implementation | Technical review of application architecture and implementation quality (focused on PaaS solutions) | [Show](./Templates/Review-AppArchitectureAndImplementation.md) |
| Guideline | DevOps | Strategy and implementation concept for consistent and standardized alerting with Azure PaaS applications| [Show](./Templates/Guideline-AlertingStrategy) |

### Knowledge
In that folder various "Knowhow", "Tips & Tricks" and "Best Practices" content is collected, e.g. regarding setup of Azure service configurations or selection of most appropriate Azure Service for specific requirements.

| Type | Scope | Description | Link |
|------|-------|-------------|------|
| Best Practices | Power BI | Tips for creating valuable Application Dashboards to empower the project/product team with deep knowledge | [Show](./Knowledge/BestPractices-PowerBI-ApplicationDashboards) |
| Best Practices | Azure Solutions | Overview of services used and usable for monitoring and analytics, its relations and best practices to use them in PaaS/Serverless architectures | [Show](./Knowledge/BestPractices-AzureSolutions-Monitoring) |
| Best Practices | App Registrations | App Registrations are often used by resources such as Bot Service or App Services / Functions to grant access to API's or for user authentication. With a continuous deployment approach, there are certain challenges to ensure correct availability and continuity with the secret lifecycle. | [Show](./Knowledge/BestPractices-AppRegistrations) |
| Knowhow | Azure Bot Service | Infographic (or schematic architecture) displaying the relationship of the various components and resources to build and run Azure Bot Service implementations. Includes Power Virtual Agent and Bot Framework tools such as the Composer or Emulator. | [Show](./Knowledge/Knowhow-AzureBotService-Overview) |
| Tips & Tricks | Azure Management REST API | For almost every resource type as well as for the central Azure Resource Manager there is a [comprehensive REST API provided, which is also well documented](https://docs.microsoft.com/en-us/rest/api/azure/). However, the documentation and most of other internet resources just demonstrate how to authenticate a service principal for application access. This requires you to assign according permissions to resources (RBAC), which is not always wanted or even possible. For API calls with Postman you maybe want a delegated access based on your personal account. | [Show](./Knowledge/TipsAndTricks-ManagementApi-Postman) |
| Best Practices | Azure Cost Management | How to enhance the Azure Cost controlling in your subscriptions by the setup of Budget and associated alerts.|[Show](./Knowledge/BestPractices-CostManagement/)|

## Support
If you need help with some content or find a bug then you may [create an issue](https://github.com/garaio/AzureRecipes/issues). For further inquiries please use contact possibilities on the [official website](https://garaio.com).

## License
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

- **[MIT license](http://opensource.org/licenses/mit-license.php)**
- Copyright 2023 © <a href="https://garaio.com" target="_blank">GARAIO AG</a>
