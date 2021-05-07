using Azure.Messaging.ServiceBus;
using FunctionApp.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
    public static class PostEventConfig
    {
        [FunctionName(nameof(PostEventConfig))]
        public static async Task<IActionResult> RunAsync(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = Constants.Routes.EventConfigs)] HttpRequest req,
            ILogger log,
            CancellationToken cancellationToken)
        {
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var entity = JsonConvert.DeserializeObject<PseudoEvent>(requestBody);
            if (entity == null)
            {
                return new BadRequestResult();
            }

            var timestamp = entity.EventTimestamp.AddMinutes(-entity.LeadTimeInMinutes);
            if (timestamp < DateTimeOffset.UtcNow)
            {
                return new NoContentResult();
            }

            var payload = new EventDispatchTrigger
            {
                DispatchedAt = DateTimeOffset.UtcNow,
                Payload = entity,
                PayloadType = nameof(PseudoEvent),
                EntityId = entity.Id.ToString(),
                EntityTag = DateTimeOffset.UtcNow.ToString("O") // For Cosmos DB entities this could be the ETag value
            };

            var message = new ServiceBusMessage
            {
                Subject = nameof(EventDispatchTrigger),
                MessageId = entity.Id.ToString(),
                Body = BinaryData.FromObjectAsJson(payload),
                ContentType = "application/json",
                CorrelationId = Guid.NewGuid().ToString()
            };

            await FunctionHelper.ScheduleTrigger(message, timestamp, log, cancellationToken);

            return new OkResult();
        }
    }
}
