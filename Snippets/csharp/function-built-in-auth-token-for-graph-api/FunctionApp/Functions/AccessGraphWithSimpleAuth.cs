using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using System;
using System.Diagnostics.CodeAnalysis;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
	/// <summary>
	/// This variant manually optains a token with an HTTP request and works without any additional dependencies
	/// </summary>
	public static class AccessGraphWithSimpleAuth
	{
		[SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
		[FunctionName(nameof(AccessGraphWithSimpleAuth))]
		public static async Task RunAsync(
			[TimerTrigger("%" + Constants.Configurations.LoadFuncSchedule + "%")] TimerInfo timer,
			ILogger log, 
			CancellationToken cancellationToken)
		{
			if (!Configurations.BuiltInAuth.IsEnabled)
            {
				log.LogWarning("Function is not linked with an app registration");
				return;
            }

			string token = await FunctionHelper.ObtainTokenAsync(Constants.AuthScopes.Graph);

			// Get an Authenticated Microsoft Graph client using the token issued to the application or user
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

			// Assign application permission 'Organisation.Read.All' for testing
			var organisation = await graphClient.Organization.Request().GetAsync(cancellationToken);
			Console.WriteLine(organisation);
		}
	}
}