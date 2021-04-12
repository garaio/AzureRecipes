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
		/// <summary>
		/// Gathers a non-cached token from Microsoft login (rather for testing use cases)
		/// </summary>
		public static async Task<string> ObtainTokenAsync(string scope)
		{
			if (!Configurations.BuiltInAuth.IsEnabled)
				return null;

			using HttpClient client = new();

			client.BaseAddress = new Uri("https://login.microsoftonline.com", UriKind.Absolute);

			using FormUrlEncodedContent form = new(new[]
			{
				new KeyValuePair<string, string>("client_id", Configurations.BuiltInAuth.ClientId),
				new KeyValuePair<string, string>("client_secret", Configurations.BuiltInAuth.ClientSecret),
				new KeyValuePair<string, string>("scope", scope),
				new KeyValuePair<string, string>("grant_type", "client_credentials"),
			}) ;
			
			Uri authUrl = new(Configurations.BuiltInAuth.TenantId + "/oauth2/v2.0/token", UriKind.Relative);
			HttpResponseMessage response = await client.PostAsync(authUrl, form).ConfigureAwait(false);

			Stream responseStream = await response.Content.ReadAsStreamAsync().ConfigureAwait(false);
			JsonElement responseObject = await JsonSerializer.DeserializeAsync<JsonElement>(responseStream).ConfigureAwait(false);
			string token = responseObject.GetProperty("access_token").GetString();

			return token;
		}
	}
}