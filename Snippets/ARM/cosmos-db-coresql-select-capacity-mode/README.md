This snippet deployes a Cosmos DB account with following properties:
* Continous backup, enabling point in time restore (GA since August 2021)
* Selection of tier & scaling based on the fact that Synapse Link is enabled or not (Synapse Link still not supports Serverless tier)
* Generation of a sample database and container with shared throughput provisioning (i.e. on database, not on single containers)

References:
* This snipped can be directly used with the Blueprint "Analytics Platform"(../../../Blueprints/analytics-platform)
* [MSDN Introduction to provisioned throughput in Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/set-throughput)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Fcosmos-db-coresql-select-capacity-mode%2Fazuredeploy.json)