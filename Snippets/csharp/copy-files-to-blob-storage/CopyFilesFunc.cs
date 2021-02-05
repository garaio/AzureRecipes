using System;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.IO.Compression;
using System.Threading.Tasks;
using Flurl.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Shared.Protocol;
using MimeMapping;

namespace FunctionApp.Functions
{
    public static class CopyFilesFunc
    {
        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(CopyFilesFunc))]
        public static async Task Run([TimerTrigger("0 0 0 1 1 *", RunOnStartup = true)]TimerInfo timer, ExecutionContext context, ILogger log)
        {
            log.LogInformation($"Copy files triggered");

            CloudBlobClient blobClient = CloudStorageAccount.Parse(Configurations.StorageConnectionString).CreateCloudBlobClient();

            CloudBlobContainer container = blobClient.GetContainerReference(Constants.Configurations.TargetContainer);
            await container.CreateIfNotExistsAsync();

            // Example: Download ZIP-file from somewhere (in this case a Github repository)
            var url = Environment.GetEnvironmentVariable(Constants.Configurations.SourceFileUrl);

            var zipStream = await url.GetStreamAsync();

            // Unpack zip to container
            using (ZipArchive archive = new ZipArchive(zipStream))
            {
                var entries = archive.Entries;
                foreach (var entry in entries)
                {
                    CloudBlockBlob blob = container.GetBlockBlobReference(entry.FullName);

                    using (var stream = entry.Open())
                    {
                        await blob.UploadFromStreamAsync(stream);
                    }

                    // Important: Content type is not detected automatically. If you don't do this, all blobs will be of type 'application/octet-stream'
                    blob.Properties.ContentType = MimeUtility.GetMimeMapping(entry.Name);
                    await blob.SetPropertiesAsync();

                    // Append metadata to blob
                    IDictionary<string, string> metadata = new Dictionary<string, string>();
                    metadata.Add("LastWriteTime", entry.LastWriteTime.ToString("s"));
                    await blob.SetMetadataAsync(metadata);
                }
            }

            log.LogInformation($"Copy files successfully executed");
        }
    }
}
