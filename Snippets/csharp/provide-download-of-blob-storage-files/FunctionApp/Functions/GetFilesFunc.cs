using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Sas;
using FunctionApp.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
    public static class GetFilesFunc
    {
        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(Get))]
        public static async Task<IActionResult> Get(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = Constants.Routes.Files)] HttpRequest req,
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
    }
}
