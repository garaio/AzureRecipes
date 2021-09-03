﻿The Azure SQL PaaS service has quite a big variety of service tiers and according configurations. This snippet provides the cheapest configuration which can be seriously used for productive applications. This configuration serves low usage / performance requirements, but can easily be scaled to mid-range use cases. It also includes the network configuration to allow access for all Azure services (e.g. App Service or Synapse).

Further information to service models / tiers:
* [MSDN Choose between the vCore and DTU purchasing models](https://docs.microsoft.com/en-us/azure/azure-sql/database/purchasing-models)
* Purchase model `vCore`: Allows cost-savings with Hybrid Benefit and Reserved Instances, but is generally rather expensive
  * [Tier `Provisioned`](https://docs.microsoft.com/en-us/azure/azure-sql/database/service-tiers-sql-database-vcore#service-tiers): Several sizes available
  * [Tier `Serverless`](https://docs.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview): Caution when allowing down-scaling to zero instances (long latencies possible)
* [Purchase model `DTU`](https://docs.microsoft.com/en-us/azure/azure-sql/database/service-tiers-dtu): Very difficult to pre-estimate the required size, but generally very cost-efficient
* [Scale up/down](https://docs.microsoft.com/en-us/azure/azure-sql/database/scale-resources): Except for the serverless tier (vCore purchase model), there is no easy configurable auto-scaling available, only a manual scaling by adjusting the size (no to minimal downtime). This can be automated with e.g. an [Automation Account script](https://techcommunity.microsoft.com/t5/azure-database-support-blog/how-to-auto-scale-azure-sql-databases/ba-p/2235441)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Fdtu-based-sql-database-for-paas-solutions%2Fazuredeploy.json)