# Deprecation Notice
This implementation based on the now deprecated [`Microsoft.Azure.Cosmos.Table` SDK](https://learn.microsoft.com/en-us/dotnet/api/overview/azure/tables/tables). It has been replaced with the [`Azure.Data.Tables` SDK](https://learn.microsoft.com/en-us/dotnet/api/overview/azure/data.tables-readme) which contains some improvements, such as a generelly simplified usage and operations for upserting and merging of entities.

> Migration Guide: https://github.com/Azure/azure-sdk-for-net/blob/main/sdk/tables/Azure.Data.Tables/MigrationGuide.md

> To consider: The limitation that only a [very limited set of property types](https://learn.microsoft.com/en-us/rest/api/storageservices/understanding-the-table-service-data-model#property-types) can be used also applies to the new SDK. Unlike the old SDK, the new SDK unfortunately does not yet provide a serious way to implement custom serialization (such as the solution presented in this snippet, which automatically serializes non-compliant types as JSON strings). This issue is discussed here: https://github.com/Azure/azure-sdk-for-net/issues/27413

---

# Introduction
Tables in Storage Account or Cosmos DB provides a very easy to use solution to store simple and not very critical data. As Storage Tables are extremly cheap, can store an almost unlimited amount of entries and are easily connectable from within Power BI, this sample shows a logging scenario as a typical use case.

# Key Concepts
## Modelling
The properties `PartitionKey` and `RowKey` must be provided and the combination of them has to be unique. Use them appropriately. In the base class `EntityBase` there is a pattern and helper function which simplifies the concatenation and splitting to/from a single identifier.

## Data Types
Supported data types are very much limited. This includes e.g. enum or collection properties. Therefore the attribute `EntityJsonPropertyConverter` is provided. This just serializes those properties to and from JSON.

## Client for Functions
For performance reasons it is recommended to not instantiate the client for the table connection on each request. The `FunctionHelper` class provides a possible way to handle that.

# Further Notes
* Storage Tables do not index "columns" other than PartitionKey and RowKey and return rows always sorted by those two values (i.e. they do not support any custom sorting). Consider the usage of Cosmos DB Core SQL API if you have requirements for querying the entries.
* Storage Tables don't provide any built in backup & restore functionality. If needed, this has to be done with a custom solution (AzCopy, Data Factory, ...). Consider the usage of Cosmos DB Table API if this is a requirement.