using System;

namespace FunctionApp.Model
{
    public class EventDispatchTrigger
    {
        public DateTimeOffset DispatchedAt { get; set; }

        public object Payload { get; set; }

        public string PayloadType { get; set; }

        public string EntityId { get; set; }

        public string EntityTag { get; set; }
    }
}
