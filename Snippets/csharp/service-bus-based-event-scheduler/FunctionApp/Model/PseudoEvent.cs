using System;

namespace FunctionApp.Model
{
    public class PseudoEvent
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string EventId { get; set; }
        public string EventType { get; set; }
        public string EventInfo { get; set; }
        public DateTimeOffset EventTimestamp { get; set; }
        public int LeadTimeInMinutes { get; set; }
        public RecurrenceIntervall RecurrenceIntervall { get; set; }
    }
}
