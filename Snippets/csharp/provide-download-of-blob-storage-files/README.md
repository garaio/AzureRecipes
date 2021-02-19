# Introduction
Azure Blob Storage is a great basis to store or buffer files for an application with document management functionality. On this base you can generate download URL's with limited accessibility (regarding e.g. time or IP address of clients).
You may activate [public read access on the parent container](https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal) which allows you to easily generate the download URI. In many situations this is not an appropriate solution as you need to control the accessibility of the files and to prevent URL manipulation. In such situations you may generate a file/blob-specific URI which is only temporary valid.

# Getting Started
Ensure that following Nuget packes are installed:
* `Microsoft.NET.Sdk.Functions` (tested with 3.0.11)
* `Azure.Storage.Blobs` (tested with 12.8.0)
* `Newtonsoft.Json` (tested with 12.0.3)

Then you can adapt the [function `GetFilesFunc`](./FunctionApp/Functions/GetFilesFunc.cs) in your Function App.

# References
* [MSDN Overview Blob Storage Client Library v12](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-dotnet)
* [MSDN Create a service SAS for a container or blob](https://docs.microsoft.com/en-us/azure/storage/blobs/sas-service-create?tabs=dotnet#create-a-service-sas-for-a-blob)
