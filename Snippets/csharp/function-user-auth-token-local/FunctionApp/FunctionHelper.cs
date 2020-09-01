using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace FunctionApp
{
	public static class FunctionHelper
	{
		public static async Task<string> ObtainTokenAsync()
		{
			using HttpClient client = new HttpClient();

			client.BaseAddress = new Uri("https://login.microsoftonline.com", UriKind.Absolute);

			using FormUrlEncodedContent form = new FormUrlEncodedContent(new[]
			{
				new KeyValuePair<string, string>("client_id", Environment.GetEnvironmentVariable(Constants.Configurations.FunctionAuthAppId)),
				new KeyValuePair<string, string>("client_secret", Environment.GetEnvironmentVariable(Constants.Configurations.FunctionAuthAppSecret)),
				new KeyValuePair<string, string>("scope", "https://graph.microsoft.com/.default"),
				new KeyValuePair<string, string>("grant_type", "client_credentials"),
			});

			Uri authUrl = new Uri(Environment.GetEnvironmentVariable(Constants.Configurations.FunctionAuthTenantId) + "/oauth2/v2.0/token", UriKind.Relative);

			HttpResponseMessage response = await client.PostAsync(authUrl, form).ConfigureAwait(false);

			Stream responseStream = await response.Content.ReadAsStreamAsync().ConfigureAwait(false);
			JsonElement responseObject = await JsonSerializer.DeserializeAsync<JsonElement>(responseStream).ConfigureAwait(false);
			string token = responseObject.GetProperty("access_token").GetString();

			return token;
		}
	}
}