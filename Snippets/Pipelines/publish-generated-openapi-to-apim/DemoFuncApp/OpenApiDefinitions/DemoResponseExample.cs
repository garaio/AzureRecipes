using DemoFuncApp.Model;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Abstractions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Resolvers;
using Newtonsoft.Json.Serialization;
using System;

namespace DemoFuncApp.OpenApiDefinitions
{
    public class DemoResponseExample : OpenApiExample<DemoResponse>
    {
        public override IOpenApiExample<DemoResponse> Build(NamingStrategy namingStrategy = null)
        {
            Examples.Add(OpenApiExampleResolver.Resolve(
                "success",
                new DemoResponse
                {
                    Version = "1.0.0"
                },
                namingStrategy
            ));

            Examples.Add(OpenApiExampleResolver.Resolve(
                "error",
                new DemoResponse
                {
                    Version = "(unknown)"
                },
                namingStrategy
            ));

            return this;
        }
    }
}
