using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using System;

namespace ServiceFunctionApp
{
    public static class FunctionHelper
    {
        public static readonly Lazy<JsonSerializerSettings> SerializerSettings = new Lazy<JsonSerializerSettings>(() => new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver(), NullValueHandling = NullValueHandling.Ignore });

        public static string ToJson(object value)
        {
            return JsonConvert.SerializeObject(value, SerializerSettings.Value);
        }
    }
}
