using Common.Model;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ServiceFunctionApp;

[assembly: FunctionsStartup(typeof(Startup))]
namespace ServiceFunctionApp
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddDbContext<DemoDbContext>(options => options.UseCosmos(Configurations.CosmosAccountEndpoint, Configurations.CosmosAccountKey, Configurations.CosmosDatabaseName));
        }
    }
}
