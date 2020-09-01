using Common;
using Common.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Threading.Tasks;

namespace ServiceFunctionApp.Functions
{
    public static class LogEntries
    {
        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(Get) + nameof(LogEntries))]
        public static async Task<IActionResult> Get(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = Constants.Routes.LogEntries + "/{key}")] HttpRequest req,
            string key,
            ILogger log)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                return new BadRequestResult();
            }

            var result = await EntityManager.Get<LogEntry>(Configurations.StorageConnectionString).GetAsync(key);

            if (result == null)
            {
                return new NotFoundResult();
            }

            return new OkObjectResult(FunctionHelper.ToJson(result));
        }

        [FunctionName(nameof(Create) + nameof(LogEntries))]
        public static async Task<IActionResult> Create(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = Constants.Routes.LogEntries)] HttpRequest req,
            ILogger log)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var entity = JsonConvert.DeserializeObject<LogEntry>(requestBody);
            if (entity == null)
            {
                return new BadRequestResult();
            }

            entity.PartitionKey = !string.IsNullOrWhiteSpace(entity.PartitionKey) ? entity.PartitionKey : EntityBase.DefaultPartitionKey;
            entity.RowKey = !string.IsNullOrWhiteSpace(entity.RowKey) ? entity.RowKey : EntityBase.NewRowKey;

            var result = await EntityManager.Get<LogEntry>(Configurations.StorageConnectionString).CreateOrUpdate(entity);

            if (result == null)
            {
                return new UnprocessableEntityResult();
            }

            log.LogMetric(Constants.Metrics.LogEntryStored, 1, new Dictionary<string, object> { { Constants.MetricProperties.EventType, entity.EventType ?? "n/a" } });

            return new CreatedResult(result.EntityKey, FunctionHelper.ToJson(result));
        }

        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(Update) + nameof(LogEntries))]
        public static async Task<IActionResult> Update(
            [HttpTrigger(AuthorizationLevel.Function, "put", Route = Constants.Routes.LogEntries + "/{key}")] HttpRequest req,
            string key,
            ILogger log)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                return new BadRequestResult();
            }

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var entity = JsonConvert.DeserializeObject<LogEntry>(requestBody);
            if (entity == null)
            {
                return new BadRequestResult();
            }

            var (partitionKey, rowKey) = EntityBase.ParseKeys(key);
            if (string.IsNullOrEmpty(partitionKey) || string.IsNullOrEmpty(rowKey))
            {
                return new BadRequestResult();
            }

            entity.PartitionKey = partitionKey;
            entity.RowKey = rowKey;

            var result = await EntityManager.Get<LogEntry>(Configurations.StorageConnectionString).CreateOrUpdate(entity);

            if (result == null)
            {
                return new UnprocessableEntityResult();
            }

            return new CreatedResult(key, FunctionHelper.ToJson(result));
        }

        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(Delete) + nameof(LogEntries))]
        public static async Task<IActionResult> Delete(
            [HttpTrigger(AuthorizationLevel.Function, "delete", Route = Constants.Routes.LogEntries + "/{key}")] HttpRequest req,
            string key,
            ILogger log)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                return new BadRequestResult();
            }

            var result = await EntityManager.Get<LogEntry>(Configurations.StorageConnectionString).Delete(key);

            return result ? (StatusCodeResult)new OkResult() : new NotFoundResult();
        }
    }
}
