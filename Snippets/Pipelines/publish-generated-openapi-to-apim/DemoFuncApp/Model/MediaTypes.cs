using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace DemoFuncApp.Model
{
    [JsonConverter(typeof(StringEnumConverter))]
    public enum MediaTypes
    {
        Image,
        Video
    }
}
