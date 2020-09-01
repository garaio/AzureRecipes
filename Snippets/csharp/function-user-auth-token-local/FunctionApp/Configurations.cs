using System;

namespace FunctionApp
{
    public static class Configurations
    {
        public static string FunctionAuthAppId => Environment.GetEnvironmentVariable(Constants.Configurations.FunctionAuthAppId);
        public static string FunctionAuthAppSecret => Environment.GetEnvironmentVariable(Constants.Configurations.FunctionAuthAppSecret);
        public static string FunctionAuthTenantId => Environment.GetEnvironmentVariable(Constants.Configurations.FunctionAuthTenantId);
    }
}
