# Introduction
To achieve an uncomplicated and efficient management of Azure resources, it is highly recommended to establish an according governance process. This shall mainly support the creation of Azure resources by any contributor in a consistent form. Therefore, typically Azure Policy definitions and assignments are used as well as Azure Blueprints.

Typically, a hierarchy of subscriptions using Management Groups is established to achieve a simplified RBAC control as well as for application of policies.

![Governance-Process](https://docs.microsoft.com/de-de/azure/cloud-adoption-framework/_images/get-started/governance-team-map.png)

See: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/get-started/team/cloud-governance

# Why Azure DevOps
As a best practice, every resource definition should be made script-based to achieve documentation and reproducibility. Azure DevOps is an ideal basis to manage governance definitions because of the following reasons:
* GIT repository for versioning of ARM templates or CLI scripts.
* Pipeline with connection to Azure for deployment of those definitions. Including management of according permissions and integration of approval mechanisms.
* Documentation of governance can be made in same repository (readme files or integrated wiki) ensuring high consistency

# References
* [Azure Policy built-in policy definitions](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)
