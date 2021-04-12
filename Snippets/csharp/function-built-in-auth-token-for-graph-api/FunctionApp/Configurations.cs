using System;
using System.Linq;

namespace FunctionApp
{
    public static class Configurations
    {
        /// <summary>
        /// Built-In authentication of Azure App Service and Azure Function
        /// <see href="https://docs.microsoft.com/en-us/azure/app-service/overview-authentication-authorization"/>
        /// </summary>
        public static class BuiltInAuth
        {
            public static bool IsEnabled => bool.TryParse(Environment.GetEnvironmentVariable(Constants.Configurations.BuiltInAuthEnabled), out bool authEnabled) && authEnabled;

            public static string ClientId => Environment.GetEnvironmentVariable(Constants.Configurations.BuiltInAuthClientId);
            public static string ClientSecret => Environment.GetEnvironmentVariable(Environment.GetEnvironmentVariable(Constants.Configurations.BuiltInAuthClientSecretSetting) ?? Constants.Configurations.BuiltInAuthClientSecretDefault);

            public static string TenantId => Environment.GetEnvironmentVariable(Constants.Configurations.BuiltInAuthClientIssuer)
                .Split("/", StringSplitOptions.RemoveEmptyEntries)
                .Select(x => Guid.TryParse(x, out Guid tid) ? tid : default(Guid?))
                .FirstOrDefault(x => x.HasValue)
                ?.ToString();
        }
    }
}
