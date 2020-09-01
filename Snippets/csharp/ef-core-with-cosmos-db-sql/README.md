# Introduction
The Cosmos DB Core SQL API is easily usable with the `CosmosClient` of the official SDK as shown here: https://docs.microsoft.com/en-us/azure/cosmos-db/create-sql-api-dotnet-v4.
 
However if the data model tends to be rather complex, the change tracking functionality of Entity Framework (Core) may be beneficial.

# Getting Started
* [EF Core Azure Cosmos DB Provider](https://docs.microsoft.com/en-us/ef/core/providers/cosmos/?tabs=dotnet-core-cli)

# Key Concepts
## DbContext
As a main downside compared to the simplicity of the `CosmosClient`, a `DbContext` implementation has to be defined specifically. Many examples show the configuration of the Cosmos DB connection inside this - in this sample this has been avoided to maintain the purpose of a lightweight, reusable class library (i.e. connectivity is configured on usage in the Azure Functions).

## Modelling
* The property `PartitionKey` is mandatory similar as with Storage Tables / Table API. If not definied explicitely, EF can manage this internally by combining the Discriminator value (equalling class name) and id. But it is recommended in most situation to manage it explicity to profit from according optimization (see [Partitioning in Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/partitioning-overview)). Explicit handling of `PartitionKey` needs that the default behaviour is disabled by calling `HasPartitionKey` on the entity-configuration.
* As a rather strange "default pattern", EF Core puts all entities into one Cosmos DB container and introduces a Discriminator property/column to manage it. In current sample this is avoided with the methods `HasNoDiscriminator` and `ToContainer` on each entity-configuration.
* Understand [Owned Entity Types](https://docs.microsoft.com/en-us/ef/core/modeling/owned-entities)

## Creation of database and containers
EF requires that all structures exist in Cosmos DB (i.e. they cannot be created "on-the-fly" as usually done with `CosmosClient`). As the manual creation during deployment is laborious and error-prone (with e.e. ARM template or CLI scripts), the built-in method `dbContext.Database.EnsureCreatedAsync()` is great. As this should not be called in every request (time consuming), the challenge is to properly implement it in an Azure Function which is by design stateless and unmanaged regarding lifecycle. This sample relies on an additional Function `OperationsFunctionApp` for such tasks - it uses the Timer trigger with the setting `RunOnStartup` which generally should not be used as it may run more often than expected, but in this case could be a good enough way. Otherwise the function can be called explicitely in a deployment process.

## Client for Functions
Recommendation: Use dependency injection as shown in sample `ServiceFunctionApp`.

# Further Notes
* Consider optimization of indexing by configuring according properties/columns