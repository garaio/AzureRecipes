using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Configurations;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.OpenApi.Models;
using System;
using System.Collections.Generic;

namespace DemoFuncApp
{
    /// <summary>
    /// Taken from <see href="https://github.com/Azure/azure-functions-openapi-extension/blob/main/docs/openapi-core.md#inheriting-defaultopenapiconfigurationoptions"/>
    /// </summary>
    /// <remarks>Download OpenAPI Spec: http://localhost:7012/api/openapi/v3.json</remarks>
    public class OpenApiConfigurationOptions : DefaultOpenApiConfigurationOptions
    {
        public const string CurrentVersion = "1.0.0"; // Important: This controls deployment to API Management (Major = Version in URL, Minor + 1 = Revision, Build = Only visible in revision description)
        public const string PublishedApiName = "DEMO API"; // Important: This is displayed to users in API Management Developer Portal - do not change it imprudently

        public override OpenApiInfo Info { get; set; } = new OpenApiInfo()
        {
            Version = CurrentVersion,
            Title = PublishedApiName,
            Description = "API for demonstration purpose",
            TermsOfService = new Uri("https://www.garaio.com"),
            Contact = new OpenApiContact()
            {
                Name = "GARAIO AG",
                Email = "info@garaio.com",
                Url = new Uri("https://www.garaio.com")
            },
            License = new OpenApiLicense()
            {
                Name = "MIT",
                Url = new Uri("http://opensource.org/licenses/MIT"),
            }
        };

        public override List<OpenApiServer> Servers { get; set; } = new List<OpenApiServer>()
        {
            // Info: These configurations doesn't matter at all. The correct base url is injected by a set-backend APIM policy. If no custom server URL is configured here, the localhost URL (when OpenAPI spec is stored to deployment folder) will be taken and displayed in the API view of APIM (but not in the Developer Portal). So this is cosmetical only.
            // new OpenApiServer() { Url = "https://api-test.customer.ch", Description = "INT/TEST Environment" },
            // new OpenApiServer() { Url = "https://api-prod.customer.ch", Description = "PROD Environment" }
        };

        public override OpenApiVersionType OpenApiVersion { get; set; } = OpenApiVersionType.V3;

        // This is configued on the level of the Function App already and would impact the local execution only
        // public override bool ForceHttps { get; set; } = true;
    }
}
