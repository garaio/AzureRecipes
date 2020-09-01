using System;
using Newtonsoft.Json;

namespace Common.Model
{
    public abstract class EntityBase
    {
        public EntityBase()
        {
            Id = NewId;
        }

        [JsonProperty("id")]
        public string Id { get; set; }

        public string PartitionKey { get; set; }

        public static string NewId => Guid.NewGuid().ToString("N");
    }
}
