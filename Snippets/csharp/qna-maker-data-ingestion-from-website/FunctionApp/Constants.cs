namespace FunctionApp
{
    public static class Constants
    {
        public static class Configurations
        {
            public const string StorageConnectionString = nameof(StorageConnectionString);
            public const string ConfigContainer = nameof(ConfigContainer);
            public const string WebsiteDataContainer = nameof(WebsiteDataContainer);

            public const string SyncWebsiteSchedule = nameof(SyncWebsiteSchedule);

            public const string WebsiteCrawlerHost = nameof(WebsiteCrawlerHost);
            public const string WebsiteCrawlerIgnoreList = nameof(WebsiteCrawlerIgnoreList);
            public const string WebsiteCrawlerDelayPerRequestMilliSeconds = nameof(WebsiteCrawlerDelayPerRequestMilliSeconds);

            public const string QnASubscriptionKey = nameof(QnASubscriptionKey);
            public const string QnAKnowledgebaseId = nameof(QnAKnowledgebaseId);
        }
    }
}
