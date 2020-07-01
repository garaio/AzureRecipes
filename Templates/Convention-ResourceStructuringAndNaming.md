# Resource Structuring and Naming
GARAIO AG usually realized custom applications for customers which are integrated into their application landscape on Azure. This requires an agreement on some conventions regarding the structure and setup of the application components. Ideally this is also ensured and supported with policies.

Generally we recommend to rely on Microsofts proposals for such conventions as much as possible (these have a general scope): https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices.
For mentionned project realizations following conditions typically apply:
* For simplicity the customer often only provides one subscription
* The setup and definition of the Azure resources is part of the application and completely managed in code
* As the ability to run resources on developer systems is very limited, developers needs to be able to setup isolated application deployments highly flexible (but still consistent)

To better support these requirements the following adaptions and specializations have proved to be reasonable.

This is a template which can be used to discuss and setup a project specific definition during the setup of a project.

## General Best Practices
* Name Azure resources consistent to code artefacts (e.g. Visual Studio project and namespace for a Function App)
* Maintain deployments from a single "source" and thus ensure consistency (source X is deployed to X, source Y deployed to Y)
  * All resources in a Resource Group from same deployment process
  * All functions in a Function App from same Visual Studio project
  * For resources with shared usage (typically by environments or sub-structured application modules) ensure that no redundant deployment from multiple processes occur. Example API Management: The service itself including e.g. global policies shall be distincted from the deployment of API's and Products specific to e.g. environments which are deployed individually
* Maintain a clear release-management where always the whole scope (consisting of one or more Resource Groups) is deployed. Prevent that single resources in a Resource Group are deployed individually to not loose the knowledge of "what is actually running". If a deployment of the whole application is not reasonably feasible, consistently split them up into modules with consistent specific Resource Groups, deployment processes (e.g. DevOps Pipeline) and specific versioning
* Isolate environments (e.g. DEV, TEST, INT, PROD) with Resource Groups (in same or different Subscriptions) and thus ensure that all related components can be moved or removed as simple as possible

## Resource Naming
General naming pattern:
> {customer}-{project/application}-{purpose (if multiple resources of same type exist)}-{resource-type (not for Resource Groups)}-{environment}

Examples (gro = GARAIO AG, ars = Azure Recipes):
* gro-ars-t (Resource Group for test enviroment)
* gro-ars-apim-t (API Management resource inside this Resource Group)
* gro-ars-demo-f-t (Function App in this Resource Group implementing "demo" functionality)
* groarssat (Storage Account inside this Resource Group)

Notes:
* Why include resource-type and same prefix-part of Resource Group in name? Most portal users intensively use the main search bar which is the fastest access to resources.
* Use abbreviations wherever possible to keep names short and below limitations. Use established terms (e.g. 'apim' for 'API Management') and use them consistently
* Consider [naming rules and restrictions for Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules). Some resources do not allow the '-' (such as e.g. Storage Account)
* Typical environments are:
  * d = Dev (e.g. current state of develop branch)
  * t = Test
  * i = Integration
  * p = Production
  * c/common = Resources used by all environments
  * PR- or Worklog ID = Test enviroment for testing of features during integration
  * Developer initials, e.g. jsc = Temporary enviroment for developments or tests

## Code Structure
Maintain a "Visual Studio oriented" structure with folders per resource where applicable. 

General naming pattern for folders:
> {customer}.{project/application}.{purpose (if multiple resources of same type exist)}{resource-type if applicable}

Examples (correlating to resource naming examples above):
* Gro.Ars.Deployment (main project including all general resource definitions and deployment scripts)
* Gro.Ars.DemoFuncApp (includes all Functions for "demo" functionality)
* Gro.Ars.Common (example for a code library used in multiple functions)

Notes:
* Maintain a project for all deployment definitions which are not part of single resources which are maintained in a specific folder/project
* Maintain a specific folder for resources with may defined with external designer tools based on ARM templates (for example Logic Apps and Azure Data Factories) (Visual Studio Deployment Project)