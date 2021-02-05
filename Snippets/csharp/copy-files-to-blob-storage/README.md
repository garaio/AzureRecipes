# Introduction
Azure Blob Storage is a great basis to store or buffer files for an application with document management functionality. On this base you may set up a Cognitive Search instance to provide search functionality and you also can generate download URL's with limited accessebility (regarding e.g. time or IP address of clients).
For such a solution you usually build sort of a synchronisation service which stages the document from a source system. This snippet provides a simple, trigger based function which you can use for this. It shows:
* Copy files to a blob (from a ZIP file)
* Ensure that corrent content-type is set
* Add metadata to blobs which can be used in e.g. a document overview or in a Cognitive Search index

# Getting Started
Ensure that following Nuget packes are installed:
* `Flurl` (tested with 2.8.2)
* `Flurl.Http` (tested with 2.4.2)
* `Microsoft.Azure.WebJobs.Extensions` (tested with 3.0.6)
* `Microsoft.Azure.WebJobs.Extensions.Storage` (tested with 4.0.3)
* `Microsoft.Azure.WebJobs.Script.ExtensionsMetadataGenerator` (tested with 1.2.0)
* `Microsoft.NET.Sdk.Functions` (tested with 3.0.9)
* `MimeMapping` (tested with 1.0.1.30)

Then you can adapt the [function `CopyFilesFunc`](./CopyFilesFunc.cs) in your Function App.
