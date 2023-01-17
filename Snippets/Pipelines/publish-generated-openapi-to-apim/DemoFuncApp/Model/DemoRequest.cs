using DemoFuncApp.OpenApiDefinitions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Newtonsoft.Json;
using System.ComponentModel.DataAnnotations;

namespace DemoFuncApp.Model
{
    [OpenApiExample(typeof(DemoRequestExample))]
    public class DemoRequest
    {
        [OpenApiProperty(Nullable = true, Description = "Id of the demonstration object")]
        public string Id { get; set; }

        [JsonRequired]
        [OpenApiProperty(Nullable = false, Description = "Name of the demonstration object")]
        public string Name { get; set; }

        [OpenApiProperty(Nullable = true, Description = "Enum (see raw schema view for possible values)")]
        public MediaTypes Type { get; set; }

        [OpenApiProperty(Nullable = true, Description = "Automatically generated on creation [readonly]")]
        [DataType(DataType.Url)]
        public string Url { get; set; }
    }
}
