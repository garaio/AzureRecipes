using DemoFuncApp.Model;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Abstractions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Resolvers;
using Newtonsoft.Json.Serialization;
using System;

namespace DemoFuncApp.OpenApiDefinitions
{
    public class DemoRequestExample : OpenApiExample<DemoRequest>
    {
        public override IOpenApiExample<DemoRequest> Build(NamingStrategy namingStrategy = null)
        {
            Examples.Add(OpenApiExampleResolver.Resolve(
                "sample",
                new DemoRequest
                {
                    Id = $"{Guid.NewGuid()}",
                    Name = "Demo",
                    Type = MediaTypes.Image,
                    Url = "https://picsum.photos/300/200"
                },
                namingStrategy
            ));

            return this;
        }
    }
}
