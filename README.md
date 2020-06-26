[![Azure Recipes by GARAIO AG](./Resources/Logo.svg)](https://garaio.com)

# Azure Recipes
This repository contains various guidances and artefacts collected during engineering of applications on Microsoft Azure. Most of them are based on PaaS or serverless services.

* [Contents](#contents)
  * [Blueprints](#blueprints)
  * [Snippets](#snippets)
  * [Templates](#templates)
  * [Knowledge](#knowledge)
* [Support](#support)
* [License](#license)

## Contents
The content is focused to the type of applications GARAIO AG typically develops as well as the tools and toolchain typically used for that. This includes mainly following tools:
* Azure DevOps (Code and Release Management, Pipelines)
* Visual Studio / Visual Studio Core (Engineering)
* Power BI (Analytics)

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

### Blueprints
Some quickstart templates for projects with standardized architectures.

_coming soon_

### Snippets
Directly reusable code artefacts for development, deployment or monitoring / analytics grouped by type of language or format.

| Type | Description                           | Link             |
|------|---------------------------------------|------------------|
| ARM  | [Azure Resource Manager templates](https://docs.microsoft.com/en-us/azure/templates/) for deployment definitions    | [Show](./Snippets/ARM/README.md) |
| CLI  | Azure Command Line Interface commands. This also includes queries based on [JMESPath](https://jmespath.org/) | [Show](./Snippets/CLI/README.md)  |
| csharp | Code snippets such as classes or methods for functionality e.g. in Functions. Class libraries are rather published via Nuget.  | [Show](./Snippets/csharp/README.md) |
| KQL  | [Kusto Query Language](https://docs.microsoft.com/en-us/azure/data-explorer/kusto/query/) snippets used for analytics in various services such as Application Insights, Log Analytics Workspace or Data Explorer | [Show](./Snippets/KQL/README.md)  |
| Pipelines  | Azure DevOps pipelines or pipeline tasks in either YAML or JSON format | [Show](./Snippets/Pipelines/README.md)  |
| PowerQuery | [PowerQuery M](https://docs.microsoft.com/en-us/powerquery-m/) or DAX artefacts used in Power BI (or e.g. Data Factory wrangling data flows)  | [Show](./Snippets/PowerQuery/README.md) |

### Templates
This contains document structures and contents for technical reviews and project-specific definition of guidelines or conventions.

_coming soon_

### Knowledge
In that folder various "How To" content is collected, e.g. regarding setup of Azure service configurations or selection of most appropriate Azure Service for specific requirements.

_coming soon_

## Support
If you need help with some content or find a bug then you may [create an issue](https://github.com/garaio/AzureRecipes/issues). For further inquiries please use contact possibilities on the [official website](https://garaio.com).

## License
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

- **[MIT license](http://opensource.org/licenses/mit-license.php)**
- Copyright 2020 © <a href="https://garaio.com" target="_blank">GARAIO AG</a>
