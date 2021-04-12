using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.Graph;
using System.Diagnostics.CodeAnalysis;
using System.Threading;
using System.Threading.Tasks;

namespace FunctionApp.Functions
{
	/// <summary>
	/// This variant uses an MSAL based authentication with supports caching of token (recommended solution)
	/// Adapted from <see href="https://docs.microsoft.com/en-us/graph/tutorials/azure-functions"/>
	/// </summary>
	public static class AccessGraphWithMsal
	{
		private static GraphServiceClient _graphClient;

		[SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
		[FunctionName(nameof(AccessGraphWithMsal))]
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

			if (_graphClient == null)
			{
				// Create a client credentials auth provider
				var authProvider = new BuiltInAuthProvider(
					new[] { Constants.AuthScopes.Graph },
					log);

				_graphClient = new GraphServiceClient(authProvider);
			}

			await _graphClient.Me.Request().GetAsync(cancellationToken);
		}
	}
}