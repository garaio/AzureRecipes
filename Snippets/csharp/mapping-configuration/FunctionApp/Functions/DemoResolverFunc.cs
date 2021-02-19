using FunctionApp.Common;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using System.Diagnostics.CodeAnalysis;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
    public static class DemoResolverFunc
    {
        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(Get))]
        public static async Task<IActionResult> Get(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = Constants.Routes.Demo)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation($"Resolve sample mapping triggered");

            CloudBlobClient blobClient = CloudStorageAccount.Parse(Configurations.StorageConnectionString).CreateCloudBlobClient();
            CloudBlobContainer container = blobClient.GetContainerReference(Constants.Configurations.ConfigContainer);
            CloudBlockBlob blob = container.GetBlockBlobReference("demo-content-type-mapping.json");
            
            string mappingFileContent = await blob.DownloadTextAsync();
            Mapping<string> contentTypeMapping = Mapping<string>.CreateFromFileContent(mappingFileContent);

            string contentType = contentTypeMapping.GetMatchOrDefault("Movie", "mp4");
            if (string.IsNullOrEmpty(contentType))
            {
                return new BadRequestObjectResult("No mapping found");
            }

            log.LogInformation($"Resolve sample mapping executed");

            return new OkObjectResult($"Content-type = {contentType}");
        }
    }
}
