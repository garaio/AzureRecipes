# Technical Review of Application Architecture and Implementation
The following checklist can help to assess the realisation of an Azure application (mainly focusing on PaaS architectures) at any point of the development or rollout phase.
    
<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables (File > Paste table data) -->

## Subscription
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Security Center | Plan configured | At least free plan should be activated, standard plan (with Azure Defender) depending on architecture and used components. If architecture includes IaaS resources (VM, VNET) this is highly recommended |  |
| Security Center | Security Contact and email notifications configured |  |  |
| Security Center | Continuous export of Alerts, Assessments and/or Scores to Log Analytics Workspace configured | Log Analytics Workspace must be deployed in same subscription, see [snippet for complete deployment of resources and continuous export configuration](../Snippets/ARM/security-center-configurations-for-subsription) |  |
| Partner Information | Partner reference configured on subscription | This is particularly applicable if the partner link has not already been made [at the tenant level](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/link-partner-id) |  |

## Resources
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Naming & Tagging | All resources named and tagged following the convention defined by the customer (e.g. in [Cloud Operating Model](./Structure-CloudOperatingModel)) or according to [Microsoft recommendations](./Convention-ResourceStructuringAndNaming.md) |  |  |
| Structuring | Environment specific resources (e.g. regarding deployment stages) are separated and isolated. Resource Groups do not contain resources from different environments or environment-specific resources mixed up with common/shared resources |  |  |
| Structuring | All resources in a Resource Group origin from one single deployment source |  |  |
| Structuring | The structuring with Resource Groups supports foreseeable later extensions (e.g. additional languages) and scaling measures | Typical shortcoming: Apps can only be moved to an App Service Plan in the same Resource Group |  |

## DevOps Aspects
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Infrastructure as Code (IaC) | All resource deployments and configurations are managed based on script(s) | One-time administrations (e.g. user or access configurations) may be excluded if those manual steps are clearly documented |  |
| Continuous Integration & Deployment (CI/CD) | The deployment is working to both initial or pre-existing environments fully automated. The target environment (tenant, subscription) is only a matter of configuration | One-time administrations (e.g. user or access configurations) may be excluded if those manual steps are clearly documented |  |
| Configurations | All sensitive configurations are solely managed with Key Vault and deployed using a safe deployment process  |  |  |
| Configurations | Sensitive configuration values are never stored in Git repositories but injected during deployment processes (e.g. using Azure DevOps Variable Groups) |  |  |
| Configurations | Sensitive parameters use according type definition (e.g. `securestring` in ARM templates) and are never logged or published (e.g. as outputs in ARM templates) |  |  |
| Configurations | [Key Vault references](https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references) in app settings of App Service resources are either not version-specific or the correct deployment order (using `dependsOn` in ARM templates) is ensured to prevent failures by chance |  |  |
| Consistency | The structuring and naming of the source data (Git repository) correlates to the deployed resources (e.g. Function App projects) |  |  |
| Causality | Resources are not defined or supplied from multiple sources | This mainly involves Function Apps (all included functions from same Visual Studio project and with same deployment process) and API Management. Rule: In a disaster recovery situation, a resource must be recoverable with one process. |  |

## Security
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Identity | Managed Identity assigned to all [(supported) resources](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/services-support-managed-identities) having connections with each other and used for authorisation | This mainly includes components executing business logic such as App Service based resources, Logic Apps or Data Factory Pipelines |  |
| Keys and Certificates | Managed with Key Vault where possible and deployed using a safe deployment process. Authorisation keys for Function Apps (host or function level) are used if connectivity is not protected in another way and a regular key exchange process is foreseen (stable, automated process) |  |  |
| TLS | TLS (HTTPS) is enforced wherever possible | Mainly includes Storage Account configuration and App Service based resources |  |

## Diagnostics & Monitoring
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Logging | Diagnostic settings for all (supported) resources set to one Log Analytics Workspace (per application & environment) with all relevant event types which may support analytics | Also [Application Insights are workspace-based](https://docs.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource) |  |
| Logging | The ingested data volume of Application Insights resource(s) is examined and validated that production usage does not generate unexpected or unreasonable costs | You may consider reduction of [log levels or event sources](https://docs.microsoft.com/en-us/azure/azure-monitor/app/asp-net-trace-logs) or apply [sampling](https://docs.microsoft.com/en-us/azure/azure-monitor/app/sampling) |  |
| Alerting | For non-user driven processes (e.g. synchronisation or import/export jobs) an error handling strategy is realized |  |  |
| Alerting | Defined SLA aspects are measured with metrics (SLI) and alerted when becoming critical | See [Best Practices for Monitoring](../Knowledge/BestPractices-AzureSolutions-Monitoring) |  |
| Error Handling | Enduring runtime errors are escalated and an according process is available | Typical checks are Logic Apps (with a number of automatic resubmits) and Service Bus Dead Letter Queue handling |  |

## Availability & Resilience
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Cost Optimisation | [Capacity reservations](https://azure.microsoft.com/en-us/reservations/) (mainly for productive environment) examined including dimensioning and proposed to owner | Beside reserved instances for VM's, capacity reservations are mostly available for data storage services (Log Analytics Workspace / Sentinel, Synapse, Cosmos and SQL databases and others) |  |
| Cost Optimisation | The implementation does not lead to an unexpected growth of costs regarding the stored data | Blobs may be moved or deleted with [lifecycle management rules](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-lifecycle-management-concepts), data in Cosmos DB or Queue systems may use a [Time to Live (TTL) definition](https://docs.microsoft.com/en-us/azure/cosmos-db/time-to-live) or other clean-up processes may be foreseen |  |
| Scaling | The resources adapt to the expected workloads (amount of use) without being oversized for the regular load. The concept is well-thought-out and documented. | For validation, take every exposed endpoint (i.e. user interface, API or event sources such as Event Grids) and follow the lineage of dependant resources. |  |
| Scaling | On resources with auto-scaling functionality enabled, the according scale-down rules are appropriately configured |  |  |
| Disaster Recovery | Data is classified and data storage resources have appropriate backup procedures and recovery process is foreseen, tested and known to those responsible. RPO and RTO metrics are well-thought-out and documented. Recovery processes do not (likely) cause troubles due to data inconsistencies with other resource. | As Table Storage (Storage Account) does not have automatic backup functionality, it should not be used for critical data (replace with Cosmos DB) or you need to provide an according process (e.g. using Data Factory Pipelines) |  |
| Disaster Recovery | Cognitive Search Indexes can be recovered and rebuilt |  |  |
| Cold Start Behaviour | APIs provided with Function Apps in Consumption plan do not cause unexpected cold start issues. App Service based resources have `AlwaysOn` configuration appropriately set. | Use a premium or dedicated plan for such Functions |  |
| Timeout Behaviour | Function Apps may not (likely) run into an execution timeout, which is configured to an appropriate value | Use a premium or dedicated plan for such Functions which supports longer timeout configuration or implement logic with a Durable Function. In case of uncertainty, you may create an Alert which informs you about longer durations before timeouts occur. |  |
| Latency | Resources run in the appropriate Azure region close to the users and all in the same region as far as possible and reasonable, especially resources which exchange high data volumes |  |  |
| Geographic Availability | The availability according to customer's needs and specifications is appropriately foreseen | This also applies in particular to data replication |  |
| Redundancy | The replication configuration (e.g. for [Storage Accounts](https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy)) is appropriately configured | Consider separation of data (especially business and application data) to multiple Storage Accounts with appropriate configuration |  |
| Soft Delete | Activated on Key Vault instances (generally recommended) and examined for Blob Storage resources |  |  |
| Archiving | Data retention ensured according to requirements | This may include the use of [lifecycle management rules for Blob Storage (with retention policies)](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-lifecycle-management-concepts) |  |
| Resource Protection | Critical production resources are protected with locks, if this risk is not mitigated by RBAC |  |  |

## Other
| Scope | Check | Notes | Result |
|-------|-------|-------|--------|
| Advisor | The Azure Advisor Recommendations are examined and reasonable proposals are implemented |  |  |
| Security Center | The Security Center Score and Recommendations are examined and reasonable proposals are implemented |  |  |
