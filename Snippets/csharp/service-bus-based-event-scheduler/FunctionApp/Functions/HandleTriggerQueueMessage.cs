using Azure.Messaging.ServiceBus;
using FunctionApp.Model;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
    public static class HandleTriggerQueueMessage
    {
        [FunctionName(nameof(HandleTriggerQueueMessage))]
        public static async Task RunAsync([ServiceBusTrigger(
            queueName: "%" + Constants.Configurations.ServiceBusQueueName + "%",
            Connection = Constants.Configurations.ServiceBusConnectionString)]
            ServiceBusReceivedMessage message,
            ILogger log,
            CancellationToken cancellationToken)
        {
            if (message == null || (message.Body?.ToArray()?.Length ?? 0) < 0 || message.Subject != nameof(EventDispatchTrigger))
                return;

            log.LogInformation($"Service Bus trigger message received (id={message.MessageId}, enqueued={message.EnqueuedTime})");

            var trigger = message.Body.ToObjectFromJson<EventDispatchTrigger>();

            // Note: At this place you would load the entity referenced by trigger information from data storage
            var entity = JsonConvert.DeserializeObject<PseudoEvent>(JsonConvert.SerializeObject(trigger.Payload));
            var entityTag = trigger.EntityTag; // For Cosmos DB entities this could be the ETag value

            // Check if entity version is still current: If not, another message has been scheduled already
            if (entityTag != trigger.EntityTag)
            {
                log.LogInformation($"Non-current trigger message detected and ignored (id={message.MessageId}, enqueued={message.EnqueuedTime})");
                return;
            }

            // Dispatch event
            // Something like: Dispatch an event to EventGrid

            // Schedule recurring event
            if (entity.RecurrenceIntervall != RecurrenceIntervall.None)
            {
                var nextTimestamp = entity.EventTimestamp.AddMinutes(-entity.LeadTimeInMinutes);
                var diff = DateTimeOffset.UtcNow - nextTimestamp;

                switch (entity.RecurrenceIntervall)
                {
                    case RecurrenceIntervall.Daily:
                        {
                            nextTimestamp.AddDays(Math.Ceiling(diff.TotalDays));
                            break;
                        }
                    case RecurrenceIntervall.Weekly:
                        {
                            nextTimestamp.AddDays(Math.Ceiling(diff.TotalDays / 7) * 7);
                            break;
                        }
                    case RecurrenceIntervall.Monthly:
                        {
                            nextTimestamp.AddMonths((int)Math.Ceiling(diff.TotalDays / 30));
                            break;
                        }
                    case RecurrenceIntervall.Yearly:
                        {
                            nextTimestamp.AddYears((int)Math.Ceiling(diff.TotalDays / 365));
                            break;
                        }
                    default:
                        {
                            log.LogError($"Type '{entity.RecurrenceIntervall}' of recurrence not supported");
                            return;
                        }
                }

                var payload = new EventDispatchTrigger
                {
                    DispatchedAt = DateTimeOffset.UtcNow,
                    Payload = entity,
                    PayloadType = nameof(PseudoEvent),
                    EntityId = trigger.EntityId,
                    EntityTag = trigger.EntityTag
                };

                var nextMessage = new ServiceBusMessage
                {
                    Subject = nameof(EventDispatchTrigger),
                    MessageId = trigger.EntityId,
                    Body = BinaryData.FromObjectAsJson(payload),
                    ContentType = "application/json",
                    CorrelationId = message.CorrelationId
                };

                await FunctionHelper.ScheduleTrigger(nextMessage, nextTimestamp, log, cancellationToken);
            }
        }
    }
}
