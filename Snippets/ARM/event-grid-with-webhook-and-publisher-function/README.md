[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Fevent-grid-with-webhook-and-publisher-function%2Fazuredeploy.json)

# Azure Event Grid Viewer
Microsoft provided a simple test application which provides a WebHook URL. You get it from: https://docs.microsoft.com/en-us/samples/azure-samples/azure-event-grid-viewer/azure-event-grid-viewer

# Sample implementation in Azure Function
Install Nuget package:
```xml
<PackageReference Include="Microsoft.Azure.EventGrid" Version="3.2.0" />
```

As functions should share client instances as much as possible, this could be implemented as follows:
```csharp
public static readonly Lazy<EventGridClient> EventGridClient = new Lazy<EventGridClient>(() => new EventGridClient(new TopicCredentials(Configurations.EventGridTopicKey)));
public static readonly Lazy<string> EventGridTopicHostname = new Lazy<string>(() => new Uri(Configurations.EventGridTopicEndpoint).Host);

public static async Task PublishEvent(EventGridEvent @event, ILogger log)
{
    var events = new[] { @event };

    try
    {
        await EventGridClient.Value.PublishEventsAsync(EventGridTopicHostname.Value, events);
    }
    catch (Exception e)
    {
        log.LogError(e, "Publish events to EventGrid failed");
    }
}
```

Functions can then dispatch events in a very simple way:
```csharp
var @event = new EventGridEvent()
{
    Id = Guid.NewGuid().ToString(),
    EventType = "Namespace.EventType",
    Data = results,
    EventTime = DateTime.UtcNow,
    Subject = $"Sample Event",
    DataVersion = "1.0"
};

await FunctionHelper.PublishEvent(@event, log);
```