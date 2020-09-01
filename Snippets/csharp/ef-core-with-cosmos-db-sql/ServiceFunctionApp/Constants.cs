namespace ServiceFunctionApp
{
    public static class Constants
    {
        public static class Configurations
        {
            public const string CosmosAccountEndpoint = nameof(CosmosAccountEndpoint);
            public const string CosmosAccountKey = nameof(CosmosAccountKey);
            public const string CosmosDatabaseName = nameof(CosmosDatabaseName);
        }

        public static class Routes
        {
            public const string UserProfile = "user";
        }
    }
}
