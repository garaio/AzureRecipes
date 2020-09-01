using System;

namespace Common.Model
{
    public class LogEntry : EntityBase
    {
        public DateTimeOffset CreatedAt => DateTimeOffset.TryParse(RowKey, out var ts) ? ts : default;

        public DateTimeOffset LastModifiedAt => Timestamp;

        public string UserId
        {
            get { return PartitionKey; }
            set { PartitionKey = value; }
        }

        public string EventType { get; set; }

        [EntityJsonPropertyConverter]
        public object Payload { get; set; }
    }
}
