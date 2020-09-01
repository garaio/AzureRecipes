using FunctionApp;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using System;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;

namespace Akbs.ChatBot.SyncJobs
{
	public static class LoadGraphData
	{
#if !DEBUG
		[FunctionName(nameof(LoadGraphData))]
		public static async Task RunAzure(
			[TimerTrigger("0 0 5 29 2 *")] TimerInfo timer, 
			[Token(Identity = TokenIdentityMode.ClientCredentials, Resource = "https://graph.microsoft.com")] string token,
			ILogger log)
		{
			await RunAsync(token, log).ConfigureAwait(false);
		}
#endif

#if DEBUG
		[FunctionName(nameof(LoadGraphData))]
		public static async Task RunLocal([TimerTrigger("0 0 5 29 2 *")] TimerInfo timer, ILogger log)
		{
			string token = await FunctionHelper.ObtainTokenAsync().ConfigureAwait(false);

			await RunAsync(token, log).ConfigureAwait(false);
		}
#endif

		private static async Task<User> RunAsync(string token, ILogger log, CancellationToken cancellationToken = default)
		{
			var graphClient = GetAuthenticatedClient(token);
			
			return await graphClient.Me.Request().GetAsync(cancellationToken);
		}

		// Get an Authenticated Microsoft Graph client using the token issued to the user.
		private static GraphServiceClient GetAuthenticatedClient(string token)
		{
			var graphClient = new GraphServiceClient(
				new DelegateAuthenticationProvider(
					requestMessage =>
					{
						// Append the access token to the request.
						requestMessage.Headers.Authorization = new AuthenticationHeaderValue("bearer", token);

						// Get event times in the current time zone.
						requestMessage.Headers.Add("Prefer", "outlook.timezone=\"" + TimeZoneInfo.Local.Id + "\"");

						return Task.CompletedTask;
					}));
			return graphClient;
		}
	}
}