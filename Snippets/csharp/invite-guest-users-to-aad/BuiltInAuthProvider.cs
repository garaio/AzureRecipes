using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using Microsoft.Identity.Client;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace Garaio.AzureRecipes
{
    /// <summary>
    /// This class provides an implementation of <see cref="IAuthenticationProvider"/> which provides app registration based authentication to Graph API
    /// Adapted from <see href="https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-microsoft-graph"/>
    /// </summary>
    public class BuiltInAuthProvider : IAuthenticationProvider
    {
        private readonly IConfidentialClientApplication _msalClient;
        private readonly string[] _scopes;
        private readonly ILogger _logger;

        public BuiltInAuthProvider(string[] scopes, ILogger logger, BuiltInAuthConfig config)
        {
            if (config?.IsEnabled != true)
            {
                throw new InvalidOperationException("Built-in authentication is not configured (i.e. Function or App Service is not linked with an app registration)");
            }

            _scopes = scopes;
            _logger = logger;

            _msalClient = ConfidentialClientApplicationBuilder
                .Create(config.ClientId)
                .WithAuthority(AadAuthorityAudience.AzureAdMyOrg, true)
                .WithTenantId(config.TenantId)
                .WithClientSecret(config.ClientSecret)
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
        public async Task AuthenticateRequestAsync(HttpRequestMessage request)
        {
            if (request?.Headers == null)
                return;

            // Get the current access token
            var token = await GetAccessToken();

            // Add the token in the Authorization header
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }
}
