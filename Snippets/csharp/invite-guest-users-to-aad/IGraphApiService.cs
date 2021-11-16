using System.Threading;
using System.Threading.Tasks;

namespace Garaio.AzureRecipes
{
	/// <summary>
	/// This service access the Graph API with functions for AAD user management
	/// </summary>
	public interface IGraphApiService
	{
		bool CheckIsEnabled();

		Task<bool> CheckUserExistsInActiveDirectoryAsync(string userId, CancellationToken cancellationToken = default);

		Task<string> CreateUserInvitationAsync(string userId, CancellationToken cancellationToken = default);
	}
}
