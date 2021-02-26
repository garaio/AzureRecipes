using Newtonsoft.Json;

namespace FunctionApp.Website
{
	public class TextEntry
	{
		public TextEntryType Type { get; set; }

		public string Content { get; set; } = string.Empty;

		[JsonIgnore]
		public bool IsEmpty => string.IsNullOrWhiteSpace(Content);
	}
}
