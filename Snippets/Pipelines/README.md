# Azure DevOps Pipelines or Task configurations
General resources:
* [Built-in Tasks Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/?view=azure-devops)

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

## Contents

| Service(s)                      | Architecture                | Problem / Solution                      | Related | Link                            |
|---------------------------------|-----------------------------|-----------------------------------------|---------|---------------------------------|
| (any) | - | Deployment pipeline to multiple stages based on particular build pipeline run ahead (i.e. acts as trigger) providing a deployable artifact  | [multi-stage-deployment-with-template](./multi-stage-deployment-with-template) | [cascading-ci-cd-pipelines](./cascading-ci-cd-pipelines) |
| Policies, Blueprints and other Governance resources | - | As a best practice, governance definitions applied to hierarchical Azure structures should be managed within a GIT repository and applied using a controlled deployment process. This snippets show how to achieve this with an Azure DevOps project.  | - | [policies-on-management-groups](./policies-on-management-groups) |
| Resource Group | - | Create a resource group (e.g. prior to deployment of ARM templates) having tags consisting of calculated values (PowerShell) and pipeline variables | - | [create-resource-group-with-calculated-tags](./create-resource-group-with-calculated-tags) |
| (any) | - | Download a file from any URL to the working directory of the agent | - | [download-file-from-url](./download-file-from-url) |
| (none) | - | Build and create a Nuget package and publish it to an Artifact (feed) in same DevOps project | - | [build-and-publish-nuget-to-artifacts](./build-and-publish-nuget-to-artifacts) |
| Container Registry / Instance | CaaS | Build and publish Docker container to Container Registry (CI pipeline) and deploy image to a Container Instance in a subsequent CD pipeline | - | [build-and-deploy-docker-to-container-instance](./build-and-deploy-docker-to-container-instance) |
| (any) | - | Reuse common deployment steps in a CD pipeline for multiple stages by using a template | [cascading-ci-cd-pipelines](./cascading-ci-cd-pipelines) | [multi-stage-deployment-with-template](./multi-stage-deployment-with-template) |
| (any) | - | Check if a specific resource already exists in a subscription | - | [check-if-azure-resource-exists](./check-if-azure-resource-exists) |
| (any) | - | Mainly to access KeyVault secrets from pipelines, an according Access Policy for the Service Principal must be deployed first. This snippet shows how to gather the necessary AAD Object ID. | - | [get-principal-objectid-from-arm-service-connection](./get-principal-objectid-from-arm-service-connection) |
| Key Vault | - | When an application consists of multiple modules (i.e. with independent Resource Groups and deployments), the configuration of resources in other modules such as e.g. connection strings becomes a challenge. This snippet shows the possible strategies to resolve with minimal configuration complexity.  | - | [multi-module-deployments-with-keyvault-integrations](./multi-module-deployments-with-keyvault-integrations) |
| (any) | - | Generate a new page in the DevOps Wiki and attach build artifacts - typically release data for manual distribution | - | [publish-artifacts-to-wiki](./publish-artifacts-to-wiki) |