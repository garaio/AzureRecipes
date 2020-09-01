using Common.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace ServiceFunctionApp.Functions
{
    public class UserProfile
    {
        private readonly DemoDbContext dbContext;

        public UserProfile(DemoDbContext dbContext)
        {
            this.dbContext = dbContext;
        }

        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(Get) + nameof(UserProfile))]
        public async Task<IActionResult> Get(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = Constants.Routes.UserProfile)] HttpRequest req,
            ClaimsPrincipal claimsPrincipal,
            ILogger log)
        {
            if (claimsPrincipal?.Identity?.IsAuthenticated != true)
            {
                return new UnauthorizedResult();
            }

            // Read / transform claims
            // https://docs.microsoft.com/en-us/azure/architecture/multitenant-identity/claims

            var userId = claimsPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userName = claimsPrincipal.FindFirst(ClaimTypes.Name)?.Value ?? claimsPrincipal.FindFirst("name")?.Value;
            
            var user = dbContext.Users.FirstOrDefault(u => u.PartitionKey == userId);
            if (user == null)
            {
                user = new User
                {
                    PartitionKey = userId,
                    DisplayName = userName,
                    IsActive = true
                };
                user.Roles.Add(new UserRole { RoleName = "User" });

                dbContext.Users.Add(user);
                await dbContext.SaveChangesAsync();
            }

            return user.IsActive ? (IActionResult)new OkObjectResult(FunctionHelper.ToJson(user)) : new UnauthorizedResult();
        }

#if DEBUG
        [FunctionName(nameof(Get) + nameof(UserProfile) + "Local")]
        public async Task<IActionResult> GetLocal(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = Constants.Routes.UserProfile + "Local")] HttpRequest req,
            ILogger log)
        {
            var localIdentity = new ClaimsIdentity(new[] {
                new Claim(ClaimTypes.NameIdentifier, "local"),
                new Claim(ClaimTypes.Name, "Local User (DEV)")
            }, "LOCAL");
            var localPrincipal = new ClaimsPrincipal(localIdentity);

            return await Get(req, localPrincipal, log);
        }
#endif
    }
}
