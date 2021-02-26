using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;

namespace FunctionApp.Website
{
	public class PageEntry
	{
		public int PageId { get; set; }

		public string Path { get; set; }

		public string Link { get; set; }

		public string Description { get; set; }

		public string Title { get; set; }

		public ICollection<TextEntry> Contents { get; set; } = new List<TextEntry>();

		[JsonIgnore]
		public string Text => string.Join(Environment.NewLine, Contents.Select(e => e.Content));

		[JsonIgnore]
		public string PageName => !string.IsNullOrWhiteSpace(Title) ? Title : !string.IsNullOrWhiteSpace(Path) ? string.Join(" | ", Path.Split('/', StringSplitOptions.RemoveEmptyEntries)) : "Home";
	}
}
