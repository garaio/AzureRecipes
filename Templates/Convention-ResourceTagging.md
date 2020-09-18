# Resource Tagging
Tags set on resources help to understand who created it, when it was and to which context it belongs. This mainly compensates the fact that the Activity Log becomes overwhelming and stores it's data (even if connected to a Log Analytics Workspace) for a limited amount of time only.

GARAIO AG usually realized custom applications for customers which are integrated into their application landscape on Azure. This requires an agreement on conventions regarding the application of tags. Ideally this is also ensured and supported with policies.

Generally we recommend to rely on Microsofts proposals for such conventions as much as possible (these have a general scope): https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#metadata-tags.
For mentionned project realizations following conditions typically apply:
* The setup and definition of the Azure resources is part of the application and completely managed in code
* The deployment is usually done to a Resource Group and fully correlates with it (i.e. all resources of Resource Group have the same origin and are created or updated within the same operation)

This is a standard which should be applied to all non-project related ressources and a template which can be used to discuss and setup a project specific definition during the setup of a project.

## General Best Practices
* Apply meaningful tags only and prevent confusion with information that is given by structure of resources (with subscription and resource group)
* Name key of tags following the **PascalCase** pattern

## Tagging Concept
The mainly relevant artefact for management purposes are Resource Groups. These must have tags defined to identify its purpose, context and history. Resources in these groups automatically inherit these tags but may always override its value or have additional tags defined on it. The automatical inheritance of tag values helps to identify orphaned resources (i.e. not included anymore in deployments) or to indicate its orgin when resources are manually moved from another Resource Group.

## Tags

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

| Tag Key | Description | Example | Mandatory |
|---------|-------------|---------|-----------|
| DeployedAt | Date of deployment | 2020-12-31 | Yes |
| DeployedBy | User which triggered the deployment. Note: This is not a replacement of `Approver` or `Owner` according to MSDN documentation (depending on the context these may be used additionally). | John Doe or john.doe@mail.com | Yes |
| DeployedFrom | Reference to origin of the deployment (source). May be set to e.g. `manual` or `n/a` for manual creations | DevOps - Organisation - Project - Pipeline - Run | Yes |

## Policies
The definitions of this convention can and shall be ensured using [built-in / standard policy definitions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-policies) as follows.

A [snippet of how to deploy policy assigments with ARM template](../Snippets/ARM/policy-assignment-to-resource-group-with-param-and-identity) is available in this repository.

### Tags on Resource Groups
- **Goal**: Ensure that Resource Groups have a the required tags applied and prevent creation otherwise
- **Policy Definition**: [`Require a tag on resource groups`](https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Tags/ResourceGroupRequireTag_Deny.json)
- **Policy Assigment**: To either Management Group or directly to Subscriptions (applied per tag)

### Inheritance of tags on Resources
- **Goal**: Automatically apply required tags from its parent Resource Group. This avoids the need to specify tags redundantly on each resource and automatically allows the detection of obsolete resources in a Resource Group (occuring with incremental deployment of ARM templates)
- **Policy Definition**: [`Inherit a tag from the resource group if missing`](https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json)
- **Policy Assigment**: To either Management Group, Subscription or directly to Resource Groups (applied per tag)
