# Introduction
Application often needs some kind of an event scheduler, which triggers a process in a particular point in time. This schedule must be configurable and could include multiple occurrences in a particular interval.
Luckily, the Azure Service Bus provides the functionality of [`scheduled-messages`](https://docs.microsoft.com/en-us/azure/service-bus-messaging/message-sequencing#scheduled-messages), even in its most basic plan. Based in this, such an event scheduler can be easily implemented with following advantages:
* Highly cost-efficient and scalable
* Robustness thanks to included retry-handling and dead-letter queue (all configurable)
* Order-guarantee and for most situations sufficient time-precision
* Monitoring functionality and possibilities for manual interactions (e.g. re-dispatched dead-lettered messages)

# Getting Started
The snippet implements:
* An initial definition of an event (trigger) which normally would take place after this information is persisted in a datastore. This is shown with the HTTP triggered function [`PostEventConfig`](./FunctionApp/Functions/PostEventConfig.cs).
* The function [`HandleTriggerQueueMessage`](./FunctionApp/Functions/HandleTriggerQueueMessage.cs) bases on a Service Bus trigger and is called when the configured due date is reached. It included:
  * Check if the event-/trigger-definition is still current (example: for Cosmos DB stored entities this can be done by comparing the ETag information). If the event has become obsolete, the process is aborted. Concept: If the event-definition has been updated, a new message has been placed in the Service Bus.
  * Check if the event has a definition of recurrence. If so, the next iteration is scheduled and dispatched to the Service Bus.
  * (Triggering of the process which is connected to the event)

```csharp
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
```

## Deployment (Azure Resources)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2Fcsharp%2Fservice-bus-based-event-scheduler%2Fazuredeploy.json)

# References
* [MSDN Message sequencing and timestamps](https://docs.microsoft.com/en-us/azure/service-bus-messaging/message-sequencing#scheduled-messages)
