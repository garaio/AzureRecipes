using System;

namespace FunctionApp
{
    public static class Configurations
    {
        public static string StorageConnectionString => Environment.GetEnvironmentVariable(Constants.Configurations.StorageConnectionString);
        public static string ServiceBusConnectionString => Environment.GetEnvironmentVariable(Constants.Configurations.ServiceBusConnectionString);
        public static string ServiceBusQueueName => Environment.GetEnvironmentVariable(Constants.Configurations.ServiceBusQueueName);
    }
}
