namespace FunctionApp
{
    public static class Constants
    {
        public static class Configurations
        {
            public const string StorageConnectionString = nameof(StorageConnectionString);

            public const string ServiceBusConnectionString = nameof(ServiceBusConnectionString);
            public const string ServiceBusQueueName = nameof(ServiceBusQueueName);
        }

        public static class Routes
        {
            public const string EventConfigs = "event-configs";
        }
    }
}
