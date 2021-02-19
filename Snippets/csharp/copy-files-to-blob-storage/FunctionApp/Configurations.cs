using System;

namespace FunctionApp
{
    public static class Configurations
    {
        public static string StorageConnectionString => Environment.GetEnvironmentVariable(Constants.Configurations.StorageConnectionString);
        public static string TargetContainer => Environment.GetEnvironmentVariable(Constants.Configurations.TargetContainer);
        public static string SourceFileUrl => Environment.GetEnvironmentVariable(Constants.Configurations.SourceFileUrl);
    }
}
