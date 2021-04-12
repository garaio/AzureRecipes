# C# Code snippets
General resources:
* _(none)_

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

## Contents

| Service(s)                      | Architecture                | Problem / Solution                      | Related | Link                            |
|---------------------------------|-----------------------------|-----------------------------------------|---------|---------------------------------|
| Function, Storage Table, Cosmos DB Table API | Serverless | Reference for complete setup of model classes and usage in Azure Function including an Entity-Manager class to simplify access to data and usage | - | [entitymanager-for-table-storage](./entitymanager-for-table-storage) |
| Function, Cosmos DB Core SQL API | - | Reference for complete setup of Entity Framework Core with model classes and usage in Azure Function | - | [ef-core-with-cosmos-db-sql](./ef-core-with-cosmos-db-sql) |
| Function | - | Use built-in authentication of Functions to generate a token for Microsoft Graph (application based access) including the ability to run the Function locally. Can be adapted to App Services and also to generate tokens for other type of API's where permissions can be managed with AAD App Registrations. | - | [function-built-in-auth-token-for-graph-api](./function-built-in-auth-token-for-graph-api) |
| Function | - | Copy files from any source to Blob Storage including correct setting of content-type and Blob Metadata | - | [copy-files-to-blob-storage](./copy-files-to-blob-storage) |
| Function | - | General mapping functionality based on easy editable JSON configurations, including resolution based on multiple criterias, wildcard support and fallback / default mechanism. Typically used in integration scenarios for routing definitions or content transformations.  | [Blueprint Integration Pipeline](../../Blueprints/integration-pipeline) | [mapping-configuration](./mapping-configuration) |
| Durable Function, Logic App | - | In integration scenarios, a common pattern is to use a Service Bus to manage asynchronous processing of integration tasks (realised with e.g. Logic Apps). When using the more robust peek-lock mechanism, the lock duration may end before before a long during process has completed (which leads to concurrent re-handling of the message). With this handler running in the background, this is efficiently avoided, as the lock is renewed before expiry.  | [Blueprint Integration Pipeline](../../Blueprints/integration-pipeline) | [service-bus-lock-handler](./service-bus-lock-handler) |
| Function | - | Provide SAS download URL's for files in a Blob Storage container | - | [provide-download-of-blob-storage-files](./provide-download-of-blob-storage-files) |
| Function | Bot or Search Solutions | Ingest data from crawled website to QnA Maker knowledge base | [Blueprint Virtual Agent](../../Blueprints/virtual-agent) | [qna-maker-data-ingestion-from-website](./qna-maker-data-ingestion-from-website) |
