using System;

namespace ServiceFunctionApp
{
    public static class Configurations
    {
        public static string StorageConnectionString => Environment.GetEnvironmentVariable(nameof(StorageConnectionString));
    }
}
