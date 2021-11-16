using System;
using System.Linq;
using Microsoft.Extensions.Configuration;

namespace Garaio.AzureRecipes
{
	/// <summary>
	/// This class is a wrapper around the <see cref="IConfiguration">settings of the App Service App</see> and provides directly usable configuration values calculated from the standard settings of the built-in authentication.
	/// </summary>
	public class BuiltInAuthConfig
	{
		private readonly IConfiguration _configuration;

		public BuiltInAuthConfig(IConfiguration configuration)
		{
			_configuration = configuration;
		}

		public bool IsEnabled => bool.TryParse(_configuration[Constants.Configurations.BuiltInAuthEnabled], out bool authEnabled) && authEnabled;

		public string ClientId => _configuration[Constants.Configurations.BuiltInAuthClientId];
		public string ClientSecret => _configuration[_configuration[Constants.Configurations.BuiltInAuthClientSecretSetting] ?? Constants.Configurations.BuiltInAuthClientSecretDefault];

		public string TenantId => _configuration[Constants.Configurations.BuiltInAuthClientIssuer]
			.Split("/", StringSplitOptions.RemoveEmptyEntries)
			.Select(x => Guid.TryParse(x, out Guid tid) ? tid : default(Guid?))
			.FirstOrDefault(x => x.HasValue)
			?.ToString();
	}
}
