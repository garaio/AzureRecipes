using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Queue;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System;

namespace ServiceFunctionApp
{
    public static class FunctionHelper
    {
        public static readonly Lazy<CloudBlobClient> BlobClient = new Lazy<CloudBlobClient>(() => CloudStorageAccount.Parse(Configurations.StorageConnectionString).CreateCloudBlobClient());
        public static readonly Lazy<CloudQueueClient> QueueClient = new Lazy<CloudQueueClient>(() => CloudStorageAccount.Parse(Configurations.StorageConnectionString).CreateCloudQueueClient());
        public static readonly Lazy<JsonSerializerSettings> SerializerSettings = new Lazy<JsonSerializerSettings>(() => new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver(), NullValueHandling = NullValueHandling.Ignore });

        public static string ToJson(object value)
        {
            return JsonConvert.SerializeObject(value, SerializerSettings.Value);
        }
    }
}
