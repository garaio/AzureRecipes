# Introduction
Azure Blob Storage is a great basis to store or buffer files for an application with document management functionality. On this base you may set up a Cognitive Search instance to provide search functionality and you also can generate download URL's with limited accessebility (regarding e.g. time or IP address of clients).
For such a solution you usually build sort of a synchronisation service which stages the document from a source system. This snippet provides a simple, trigger based function which you can use for this. It shows:
* Copy files to a blob (from a ZIP file)
* Ensure that corrent content-type is set
* Add metadata to blobs which can be used in e.g. a document overview or in a Cognitive Search index

# Getting Started
Ensure that following Nuget packes are installed:
* `Microsoft.NET.Sdk.Functions` (tested with 3.0.11)
* `Azure.Storage.Blobs` (tested with 12.8.0)
* `MimeMapping` (tested with 1.0.1.37)
* For sample with download of a web resource: `Flurl.Http` (tested with 3.0.1)

Then you can adapt the [function `CopyFilesFunc`](./FunctionApp/Functions/CopyFilesFunc.cs) in your Function App.

# References
* [MSDN Overview Blob Storage Client Library v12](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-dotnet)
* [MSDN Manage blob properties and metadata with .NET](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-properties-metadata?tabs=dotnet#resources-for-development-with-net)
