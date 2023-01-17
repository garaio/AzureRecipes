using System;

namespace DemoFuncApp
{
    public static class Configurations
    {
        public static string StorageConnectionString => Environment.GetEnvironmentVariable(Constants.ConfigurationNames.StorageConnectionString);
    }
}
