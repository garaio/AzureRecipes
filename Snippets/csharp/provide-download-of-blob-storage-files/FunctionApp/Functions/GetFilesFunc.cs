using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using FunctionApp.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
    public static class GetFilesFunc
    {
        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(GetV12))]
        public static async Task<IActionResult> GetV12(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = Constants.Routes.Files + "/v12")] HttpRequest req,
            ILogger log)
        {
            log.LogInformation($"Get files triggered");

            var blobContainer = new BlobContainerClient(Configurations.StorageConnectionString, Configurations.FilesContainer);

            if (!await blobContainer.ExistsAsync())
            {
                return new NoContentResult();
            }

            if (!blobContainer.CanGenerateSasUri)
            {
                return new UnauthorizedResult();
            }

            var results = new List<FileInfo>();

            // List all blobs in the container
            await foreach (BlobItem blobItem in blobContainer.GetBlobsAsync())
            {
                var blobClient = blobContainer.GetBlobClient(blobItem.Name);
                var sasBuilder = new BlobSasBuilder()
                {
                    BlobContainerName = Configurations.FilesContainer,
                    BlobName = blobClient.Name,
                    Resource = "b",
                    ExpiresOn = DateTimeOffset.UtcNow.AddHours(1)
                };
                sasBuilder.SetPermissions(BlobSasPermissions.Read);

                Uri sasUri = blobClient.GenerateSasUri(sasBuilder);

                results.Add(new FileInfo
                {
                    Name = blobItem.Name,
                    Uri = sasUri.AbsoluteUri
                });
            }

            log.LogInformation($"Found {results.Count} files");

            return new OkObjectResult(FunctionHelper.ToJson(results));
        }

        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(GetV11))]
        public static async Task<IActionResult> GetV11(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = Constants.Routes.Files + "/v11")] HttpRequest req,
            ILogger log)
        {
            log.LogInformation($"Get files triggered");

            CloudBlobClient blobClient = CloudStorageAccount.Parse(Configurations.StorageConnectionString).CreateCloudBlobClient();
            CloudBlobContainer blobContainer = blobClient.GetContainerReference(Constants.Configurations.FilesContainer);

            if (!await blobContainer.ExistsAsync())
            {
                return new NoContentResult();
            }

            var results = new List<FileInfo>();

            // List all blobs in the container
            BlobContinuationToken continuationToken = null;
            CloudBlob blob;

            do
            {
                BlobResultSegment resultSegment = await blobContainer.ListBlobsSegmentedAsync(continuationToken);

                foreach (var blobItem in resultSegment.Results)
                {
                    blob = (CloudBlob)blobItem;

                    results.Add(new FileInfo
                    {
                        Name = blob.Name,
                        Uri = new Uri(blob.Uri, blob.GetSharedAccessSignature(new SharedAccessBlobPolicy
                        {
                            SharedAccessExpiryTime = DateTimeOffset.UtcNow.AddDays(1),
                            Permissions = SharedAccessBlobPermissions.Read
                        })).AbsoluteUri
                    });
                }

                // Get the continuation token and loop until it is null.
                continuationToken = resultSegment.ContinuationToken;

            } while (continuationToken != null);

            log.LogInformation($"Found {results.Count} files");

            return new OkObjectResult(FunctionHelper.ToJson(results));
        }
    }
}
