using System;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;

namespace FunctionApp.Helpers
{
    public static class FunctionHelper
    {
        public static readonly Lazy<CloudBlobClient> BlobClient = new Lazy<CloudBlobClient>(() => CloudStorageAccount.Parse(Environment.GetEnvironmentVariable(Configurations.StorageConnectionString)).CreateCloudBlobClient());
    }
}
