# Policy Assignments for PaaS Applications
The following set of built-in policies is recommended as initial basis for typical PaaS applications. Ideally this are applied to an appropriate Management Group being parent of these applications.

| Policy | Resource Type(s) | Configuration | Effect | Purpose |
|--------|------------------|---------------|--------|---------|
| [Enable Azure Security Center on your subscription](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fac076320-ddcf-4066-b451-6154267e8ad2) | Subscription | None | DeployIfNotExists | Automatically enables free tier of Microsoft Defender |
| [Require a tag on resource groups](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F96670d01-0a4d-4649-9c89-2d3abc0a5025) | Resource Group | Assigned for following tags according to [1] | Deny | Ensure that Resource Groups have the required tags applied and prevent creation otherwise |
| [Inherit a tag from the resource group if missing](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F96670d01-0a4d-4649-9c89-2d3abc0a5025) | Resource Group | Assigned for following tags according to [1] | Modify | Automatically apply required tags from its parent Resource Group |
| [Not allowed resource types](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fea3f2387-9b95-492a-a190-fcdc54f7b070) | All | Forbidden resources see [2] | Deny | Avoid expenses and ensure guidelines |
| [Allowed locations](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fe56962a6-4747-49cd-b67b-bf8b01975c4c) | All | Switzerland North & West Europe | Deny | Ensure guidelines |
| [API App should only be accessible over HTTPS](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fb7ddfbdc-1260-477d-91fd-98bd9be789a6) | App Service | None | Audit | Security |
| [Function App should only be accessible over HTTPS](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F6d555dd1-86f2-4f1c-8ed7-5abae7c6cbab) | App Service | None | Audit | Security |
| [Web Application should only be accessible over HTTPS](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2Fa4af4a39-4135-47fb-b175-47fbdf85311d) | App Service | None | Audit | Security |
| [Allowed storage account SKUs](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F7433c107-6db4-4ad1-b57a-a76dce0154a1) | Storage Account | Standard_LRS, Standard_ZRS, Standard_GRS, Standard_RAGRS | Deny | Avoid expenses |
| [Secure transfer to storage accounts should be enabled](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F404c3081-a854-4457-ae30-26a93ef643f9) | Storage Account | None | Audit | Security |

[1] According to tagging convention:
- DeployedAt
- DeployedBy
- DeployedFrom

[2] (exkl. prefix “Microsoft.”):
- storsimple/managers
- vmwarecloudsimple/virtualmachines
- vmwarecloudsimple/locations
- vmware/virtualmachines
- vmware/vcenters
- vmware/locations
- sqlvirtualmachine/sqlvirtualmachines
- sqlvirtualmachine/sqlvirtualmachinegroups
- sqlvirtualmachine/locations
- sql/managedinstances
- servicefabric/clusters
- servicefabric/locations
- servicefabric/managedclusters
- offazure/vmwaresites
- offazure/mastersites
- offazure/locations
- offazure/hypervsites
- netapp/netappaccounts
- netapp/locations
- kubernetes/connectedclusters
- kubernetes/locations
- hybridcompute/machines
- hybridcompute/privatelinkscopes
- hybridcompute/locations
- hpcworkbench/instances
- hpcworkbench/locations
- hdinsight/clusterpools
- hdinsight/clusters
- hdinsight/locations
- hardwaresecuritymodules/dedicatedhsms
- hanaonazure/hanainstances
- hanaonazure/locations
- devtestlab/labs
- devtestlab/locations
- desktopvirtualization/applicationgroups
- desktopvirtualization/hostpools
- d365customerinsights/instances
- connectedvmwarevsphere/clusters
- connectedvmwarevsphere/datastores
- connectedvmwarevsphere/hosts
- connectedvmwarevsphere/locations
- connectedvmwarevsphere/vcenters
- connectedvmwarevsphere/virtualmachines
- compute/capacityreservationgroups
- compute/locations
- compute/virtualmachines
- compute/virtualmachinescalesets
- classiccompute/virtualmachines
- baremetalinfrastructure/baremetalinstances
- baremetalinfrastructure/locations
- azurestackhci/clusters
- azurestackhci/locations
- azurestackhci/virtualmachines
- azurestack/registrations
- azuresphere/catalogs
- azuresphere/locations
- avs/locations
- avs/privateclouds

# Best Practices
* Create a User-assigned Managed Identity in advance with the roles `Contributor` and `Security Admin` on the Management Group. Use this identity in policy assignments, this prevents the generation of hardly identifiable Service Principals.
* Especially policy assignments with many configurations (like the `Not allowed resource types`) may be hardly manageable in the Azure Portal UI. Consider its definition with ARM/Bicep templates and an according deployment process.
* Tip: Azure CLI command to show current assignments: `az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/mg-applications"` 

# References
* [MSDN Azure Policy built-in policy definitions](https://docs.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)