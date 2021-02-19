using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO.Compression;
using System.Threading.Tasks;
using Flurl.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using MimeMapping;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace FunctionApp.Functions
{
    public static class CopyFilesFunc
    {
        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(CopyFilesFunc))]
        public static async Task Run([TimerTrigger("0 0 0 1 1 *", RunOnStartup = true)]TimerInfo timer, ExecutionContext context, ILogger log)
        {
            log.LogInformation($"Copy files triggered");

            var blobClient = new BlobServiceClient(Configurations.StorageConnectionString);            
            var container = blobClient.GetBlobContainerClient(Configurations.TargetContainer);
            await container.CreateIfNotExistsAsync();

            // Example: Download ZIP-file from somewhere (in this case a Github repository)
            var url = Environment.GetEnvironmentVariable(Configurations.SourceFileUrl);

            var zipStream = await url.GetStreamAsync();

            // Unpack zip to container
            using (ZipArchive archive = new ZipArchive(zipStream))
            {
                var entries = archive.Entries;
                foreach (var entry in entries)
                {
                    var blob = container.GetBlobClient(entry.FullName);

                    // Important: Content type is not detected automatically. If you don't do this, all blobs will be of type 'application/octet-stream'
                    using (var stream = entry.Open())
                    {
                        await blob.UploadAsync(stream, new BlobHttpHeaders { ContentType = MimeUtility.GetMimeMapping(entry.Name) });
                    }

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
