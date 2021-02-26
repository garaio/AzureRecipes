# Introduction
The Cognitive Service QnA Maker is a powerful service to generate answers based on pre-learned content and is typically integrated in search engines or chatbot solutions. In such scenarios there is often the need to automatically ingest the indexed content from external data source to either avoid manual management or to enable the content editing in a system which is more common to the user (e.g. SharePoint). This snippet provides a simple synchronisation function which extracts text from website pages and copies it to a QnA Maker knowledge base.

The [blueprint 'Virtual Agent'](../../../Blueprints/virtual-agent) provides a reference architecture for usage in a Bot Framework context.

# Implementation
## Crawling
The website crawling is implemented using the great [Abot library](https://github.com/sjdirect/abot) and needs to be slightly adjusted depending on the structure and content of the website to be indexed.

## QnA Maker API
The project contains model classes which has been generated from the [official v4.0 API documentation](https://docs.microsoft.com/en-us/rest/api/cognitiveservices/qnamaker4.0/knowledgebase). It has been optimised and tested with multiple projects and it works properly even with bigger and complex datasets. In the meantime, Microsoft published an official [Nuget package `Microsoft.Azure.CognitiveServices.Knowledge.QnAMaker`](https://www.nuget.org/packages/Microsoft.Azure.CognitiveServices.Knowledge.QnAMaker) ([Source on Github](https://github.com/Azure/azure-sdk-for-net/tree/master/sdk/cognitiveservices/Knowledge.QnAMaker/src)) to interact with the management API of QnA Maker (previously a library has only been available for the runtime). Especially when working with the new QnA Maker Managed you should consider migrating to this library.

# Getting Started
You need to have a QnA Maker instance up and running. The knowledge base to be synchronize may already exist (empty or with content), otherwise it will be created automatically.

