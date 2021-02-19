using System;

namespace FunctionApp
{
    public static class Configurations
    {
        public static string StorageConnectionString => Environment.GetEnvironmentVariable(Constants.Configurations.StorageConnectionString);
        public static string FilesContainer => Environment.GetEnvironmentVariable(Constants.Configurations.FilesContainer);
    }
}
