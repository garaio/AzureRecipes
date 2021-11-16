using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using System;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace Garaio.AzureRecipes
{
    /// <inheritdoc cref="IGraphApiService"/>
    public class GraphApiService
    {
        private readonly ILogger<GraphApiService> _logger;
        private readonly IConfiguration _configuration;
        private readonly BuiltInAuthConfig _authConfig;
        private readonly Lazy<GraphServiceClient> _graphServiceClient;

        public GraphApiService(ILoggerFactory loggerFactory, IConfiguration configuration)
        {
            _logger = loggerFactory.CreateLogger<GraphApiService>();
            _configuration = configuration;
            _authConfig = new BuiltInAuthConfig(configuration);

            _graphServiceClient = new Lazy<GraphServiceClient>(() =>
            {                
                // Create a client credentials auth provider
                var authProvider = new BuiltInAuthProvider(
                    new[] { Constants.AuthScopes.Graph },
                    _logger,
                    _authConfig);

                return new GraphServiceClient(authProvider);
            });
        }

        private static bool IsValidEmail(string email)
        {
            return Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.IgnoreCase);
        }

        public bool CheckIsEnabled()
        {
            return _authConfig.IsEnabled && !string.IsNullOrEmpty(_authConfig.ClientId) && !string.IsNullOrEmpty(_authConfig.ClientSecret) && !string.IsNullOrEmpty(_authConfig.TenantId);
        }

        /// <summary>
        /// Requires permission `User.Read.All`
        /// </summary>
        public async Task<bool> CheckUserExistsInActiveDirectoryAsync(string userId, CancellationToken cancellationToken = default)
        {
            if (!IsValidEmail(userId))
            {
                _logger.LogWarning($"Invalid user-id '{userId}' detected");
                return false;
            }

            var resultPage = await _graphServiceClient.Value.Users.Request().Filter($"mail eq '{userId}'").GetAsync(cancellationToken);
            var user = resultPage.CurrentPage.FirstOrDefault();

            return user != null;
        }

        /// <summary>
        /// Requires permission `User.Invite.All`
        /// </summary>
        public async Task<string> CreateUserInvitationAsync(string userId, CancellationToken cancellationToken = default)
        {
            if (!IsValidEmail(userId))
            {
                _logger.LogWarning($"Invalid user-id '{userId}' detected");
                return null;
            }

            var invitation = new Invitation
            {
                InvitedUserEmailAddress = userId,
                InviteRedirectUrl = _configuration[Public.Constants.Configurations.FrontendUrl],
                SendInvitationMessage = false
            };          

            try
            {
                Invitation result = await _graphServiceClient.Value.Invitations.Request().AddAsync(invitation, cancellationToken);

                return result.InviteRedeemUrl;
            }
            // One typical case for this exception is, when you try to invite users with an email that belongs to the AAD's domain (i.e. existing non-guest AAD users)
            catch (ServiceException e)
            {
                var exMsg = $"Failed to invite user '{userId}' to Active Directory: {e.Message}";
                
                _logger.LogWarning(e, exMsg);

                throw new InvalidOperationException(exMsg, e); // Throw neutral exception so that service users don't need to reference Graph library
            }
        }
    }
}
