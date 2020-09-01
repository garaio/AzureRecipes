using Common.Model;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace OperationsFunctionApp.Initialization
{
    public static class InitDatabase
    {
        [FunctionName(nameof(InitDatabase))]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation($"Function {nameof(InitDatabase)} triggered by call");

            await CreateOrUpdateDatabase(log);

            return new OkResult();
        }

        [FunctionName(nameof(InitDatabase) + "AutoStart")]
        public static async Task Run([TimerTrigger("0 0 0 1 1 *", RunOnStartup = true)]TimerInfo timer, ExecutionContext context, ILogger log)
        {
            log.LogInformation($"Function {nameof(InitDatabase)} triggered by trigger");

            await CreateOrUpdateDatabase(log);
        }

        private static async Task CreateOrUpdateDatabase(ILogger log)
        {
            var options = new DbContextOptionsBuilder<DemoDbContext>();
            options.UseCosmos(Configurations.CosmosAccountEndpoint, Configurations.CosmosAccountKey, Configurations.CosmosDatabaseName);

            var context = new DemoDbContext(options.Options);

            var created = await context.Database.EnsureCreatedAsync();
            if (created)
            {
                log.LogInformation($"{Configurations.CosmosDatabaseName} along with containers created");
            }
            else
            {
                log.LogInformation($"{Configurations.CosmosDatabaseName} already exists");
            }
        }
    }
}
