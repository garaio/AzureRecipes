using Microsoft.AspNetCore.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System;

namespace DemoFuncApp
{
    public static class FunctionHelper
    {
        public static readonly Lazy<JsonSerializerSettings> SerializerSettings = new(() => new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver(), NullValueHandling = NullValueHandling.Ignore });

        /// <summary>
        /// Reads API Version from HTTP header (automatically enriched by API Management) or uses <see cref="OpenApiConfigurationOptions">currently published version</see> otherwise
        /// </summary>
        /// <remarks>This information can be used for separated handling of different versions active</remarks>
        public static Version GetApiVersion(this HttpRequest req)
        {
            var apiVersion = req.Headers.TryGetValue(Constants.Headers.ApiVersion, out var apiVersionValue) ? (string)apiVersionValue : OpenApiConfigurationOptions.CurrentVersion;

            return Version.Parse(apiVersion);
        }
    }
}
