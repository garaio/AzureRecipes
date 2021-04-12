using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using Microsoft.Identity.Client;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace FunctionApp
{
    /// <summary>
    /// Adapted from <see href="https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-microsoft-graph"/>
    /// </summary>
    public class BuiltInAuthProvider : IAuthenticationProvider
    {
        private readonly IConfidentialClientApplication _msalClient;
        private readonly string[] _scopes;
        private readonly ILogger _logger;

        public BuiltInAuthProvider(string[] scopes, ILogger logger)
        {
            if (!Configurations.BuiltInAuth.IsEnabled)
            {
                throw new InvalidOperationException("Built-in authentication is not configured (i.e. Function or App Service is not linked with an app registration)");
            }

            _scopes = scopes;
            _logger = logger;

            _msalClient = ConfidentialClientApplicationBuilder
                .Create(Configurations.BuiltInAuth.ClientId)
                .WithAuthority(AadAuthorityAudience.AzureAdMyOrg, true)
                .WithTenantId(Configurations.BuiltInAuth.TenantId)
                .WithClientSecret(Configurations.BuiltInAuth.ClientSecret)
                .Build();
        }

        public async Task<string> GetAccessToken()
        {
            try
            {
                // Invoke client credentials flow
                // NOTE: This will return a cached token if a valid one exists
                var result = await _msalClient
                  .AcquireTokenForClient(_scopes)
                  .ExecuteAsync();

                _logger.LogInformation($"App-only access token: {result.AccessToken}");

                return result.AccessToken;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Error getting access token via client credentials flow");
                return null;
            }
        }

        // This is the delegate called by the GraphServiceClient on each request
        public async Task AuthenticateRequestAsync(HttpRequestMessage requestMessage)
        {
            // Get the current access token
            var token = await GetAccessToken();

            // Add the token in the Authorization header
            requestMessage.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }
}
