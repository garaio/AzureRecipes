using DemoFuncApp.OpenApiDefinitions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;

namespace DemoFuncApp.Model
{
    [OpenApiExample(typeof(DemoResponseExample))]
    public class DemoResponse
    {
        [OpenApiProperty(Nullable = true, Description = "Version of the demonstration object")]
        public string Version { get; set; }
    }
}
