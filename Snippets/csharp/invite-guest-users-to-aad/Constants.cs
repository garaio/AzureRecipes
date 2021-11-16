namespace Garaio.AzureRecipes
{
	public static class Constants
	{
		public static class Configurations
		{
			// Built-In authentication of Azure App Service and Azure Function
			// see https://docs.microsoft.com/en-us/azure/app-service/overview-authentication-authorization
			public const string BuiltInAuthEnabled = "WEBSITE_AUTH_ENABLED";
			public const string BuiltInAuthClientId = "WEBSITE_AUTH_CLIENT_ID";
			public const string BuiltInAuthClientSecretSetting = "WEBSITE_AUTH_CLIENT_SECRET_SETTING_NAME";
			public const string BuiltInAuthClientSecretDefault = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET";
			public const string BuiltInAuthClientIssuer = "WEBSITE_AUTH_OPENID_ISSUER";
		}

		public static class AuthScopes
		{
			public const string Graph = "https://graph.microsoft.com/.default";
		}
	}
}