namespace DemoFuncApp
{
    public static class Constants
    {
        public static class ConfigurationNames
        {
            public const string StorageConnectionString = nameof(StorageConnectionString);
        }

        public static class Routes
        {
            public const string DemoEntities = "entities";
        }

        /// <summary>
        /// Consider <see href="https://docs.microsoft.com/en-us/aspnet/web-api/overview/web-api-routing-and-actions/attribute-routing-in-web-api-2#constraints"/>
        /// </summary>
        public static class RouteParams
        {
            public const string EntityId = "id";
        }

        public static class QueryParams
        {
            public const string TestFlag = "testFlag";

            public const string SubscriptionId = "subscriptionId";

            public const string UserId = "userId";
        }
        public static class ApiCategories
        {
            public const string Query = "Query";
            public const string Management = "Management";
        }

        public static class Headers
        {
            public const string ApiVersion = "Api-Version";
        }
    }
}
