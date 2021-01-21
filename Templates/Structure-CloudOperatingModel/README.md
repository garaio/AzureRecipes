# Overview
Many companies define and maintain a Cloud Operating Model (COM) document which explains the basic strategy on how to integrate Azure in their IT infrastructure. There is no concrete definition which contents this document includes as the needs vary for each company and its application and technology landscapes. The present contents are an edited collection from completed development and consulting projects.
An established approach is to start lean with definition of the currently known contents and use this document as a baseline and framework with continous adjustment and extension.

The contents are based on and adapted from the [Microsoft Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/operating-model).

# Recommendations
## Content and Usage Practices
* Do not explain or document Azure services and principles (education) as its not the purpose of this document
* For conventions rely on and reference recommended best practices in MSDN
* Keep content concise and consistent. Remove not needed chapters
* Feel free to customize the content according to your specific needs

## Management
Governance usually includes policy definitions and assignments or blueprint definitions which are at best managed with a source management system and automated deployment. A possible and recommended approach is to setup and use an Azure DevOps project for this (there is a [snippet for according deployment pipelines](../../Snippets/Pipelines/policies-on-management-groups) which includes more information to this approach). If you follow this way it may be interessting to also include the Cloud Operating Model (COM) in this DevOps project (Wiki) as it may foster consistency and provides management (such as versioning).

# Templates
- [Markdown File](./Cloud-Operating-Model.md)
- [Word Template](https://github.com/garaio/AzureRecipes/raw/master/Templates/Structure-CloudOperatingModel/Cloud%20Operating%20Model.dotx)