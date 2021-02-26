using System;

namespace FunctionApp
{
    public static class Configurations
    {
        public static string StorageConnectionString => Environment.GetEnvironmentVariable(Constants.Configurations.StorageConnectionString);
        public static string ConfigContainer => Environment.GetEnvironmentVariable(Constants.Configurations.ConfigContainer);
        public static string WebsiteDataContainer => Environment.GetEnvironmentVariable(Constants.Configurations.WebsiteDataContainer);

        public static string WebsiteCrawlerHost => Environment.GetEnvironmentVariable(Constants.Configurations.WebsiteCrawlerHost);
        public static string WebsiteCrawlerIgnoreList => Environment.GetEnvironmentVariable(Constants.Configurations.WebsiteCrawlerIgnoreList);
        public static string WebsiteCrawlerDelayPerRequestMilliSeconds => Environment.GetEnvironmentVariable(Constants.Configurations.WebsiteCrawlerDelayPerRequestMilliSeconds);
        
        public static string QnASubscriptionKey => Environment.GetEnvironmentVariable(Constants.Configurations.QnASubscriptionKey);
        public static string QnAKnowledgebaseId => Environment.GetEnvironmentVariable(Constants.Configurations.QnAKnowledgebaseId);
    }
}
