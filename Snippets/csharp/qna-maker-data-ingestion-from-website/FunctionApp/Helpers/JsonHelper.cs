using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace FunctionApp.Helpers
{
    public static class JsonHelper
    {
        public static JsonSerializerSettings SerializerSettings { get; } = new JsonSerializerSettings
        {
            ContractResolver = new CamelCasePropertyNamesContractResolver(),
            NullValueHandling = NullValueHandling.Ignore
        };

        public static string ToJson(object obj)
        {
            return JsonConvert.SerializeObject(obj, SerializerSettings);
        }

        public static T FromJson<T>(string json)
        {
            return JsonConvert.DeserializeObject<T>(json);
        }
    }
}
