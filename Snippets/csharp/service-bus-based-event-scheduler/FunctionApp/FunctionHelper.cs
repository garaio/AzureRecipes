using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace FunctionApp
{
    public static class FunctionHelper
    {
        public static readonly Lazy<ServiceBusClient> ServiceBusClient = new(() => new ServiceBusClient(Configurations.ServiceBusConnectionString));
        public static async Task ScheduleTrigger(ServiceBusMessage message, DateTimeOffset dueTimestamp, ILogger log, CancellationToken cancellationToken = default)
        {
            try
            {
                await using var sender = ServiceBusClient.Value.CreateSender(Configurations.ServiceBusQueueName);

                var seqNum = await sender.ScheduleMessageAsync(message, dueTimestamp, cancellationToken);

                log.LogInformation($"Trigger scheduled for MessageId {message.MessageId} -> SequenceNumber = {seqNum}");
            }
            catch (Exception e)
            {
                log.LogError(e, "Dispatch message to ServiceBus failed");
            }
        }

        public static readonly Lazy<JsonSerializerSettings> SerializerSettings = new(() => new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver(), NullValueHandling = NullValueHandling.Ignore });

        public static string ToJson(object value)
        {
            return JsonConvert.SerializeObject(value, SerializerSettings.Value);
        }
    }
}
