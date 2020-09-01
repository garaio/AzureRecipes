using System;

namespace OperationsFunctionApp
{
    public static class Configurations
    {
        public static string CosmosAccountEndpoint => Environment.GetEnvironmentVariable(Constants.Configurations.CosmosAccountEndpoint);
        public static string CosmosAccountKey => Environment.GetEnvironmentVariable(Constants.Configurations.CosmosAccountKey);
        public static string CosmosDatabaseName => Environment.GetEnvironmentVariable(Constants.Configurations.CosmosDatabaseName);
    }
}
