using HtmlAgilityPack;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace FunctionApp.Website
{
	public static class HtmlParser
	{
		private const string crlf = "\r\n";
		private const string space = " ";

		public static ICollection<TextEntry> ConvertToPlainText(HtmlDocument doc)
		{
			var current = new TextEntry();
			var results = new List<TextEntry>();

			ParseNode(doc.DocumentNode, ref current, ref results);

			// Clean contents
			foreach (var entry in results)
			{
				var text = entry.Content.TrimEnd();

				if (text.EndsWith(crlf))
					text = text.Substring(0, text.Length - crlf.Length);

				entry.Content = text;
			}

			return results;
		}

		private static void ParseNode(HtmlNode node, ref TextEntry current, ref List<TextEntry> results)
		{
			string text;
			switch (node.NodeType)
			{
				case HtmlNodeType.Comment:
					// don't output comments
					break;

				case HtmlNodeType.Document:
					foreach (HtmlNode subnode in node.ChildNodes)
						ParseNode(subnode, ref current, ref results);

					break;

				case HtmlNodeType.Text:
					// script and style must not be output
					string parentName = node.ParentNode.Name;
					if (parentName == "script" || parentName == "style" || parentName == "title")
						break;
					if (parentName == "span")
						parentName = node.ParentNode.ParentNode.Name;

					// get text
					text = ((HtmlTextNode)node).Text;

					// is it in fact a special closing node output as text?
					if (HtmlNode.IsOverlappedClosingElement(text))
						break;

					// check the text is meaningful and not a bunch of whitespaces
					text = HtmlEntity.DeEntitize(text).Trim();
					if (string.IsNullOrEmpty(text) || text == crlf)
						break;

					if (parentName == "li")
					{
						if (!current.IsEmpty)
						{
							results.Add(current);
							current = new TextEntry();
						}

						current.Type = TextEntryType.List;
					}
					else if (parentName == "strong" || Regex.IsMatch(parentName, @"^h\d$"))
					{
						if (!current.IsEmpty)
						{
							results.Add(current);
							current = new TextEntry();
						}

						current.Type = TextEntryType.Title;
					}

					current.Content += text;

					if (!current.Content.EndsWith(crlf))
						current.Content += crlf;

					break;

				case HtmlNodeType.Element:
					switch (node.Name)
					{
						case "p":
							if (!current.IsEmpty)
							{
								results.Add(current);
								current = new TextEntry();
							}
							break;

						case "br":
							if (current.Content.EndsWith(crlf))
								current.Content = current.Content.Substring(0, current.Content.Length - crlf.Length);

							if (!current.Content.EndsWith(space))
								current.Content += space;

							break;
					}

					if (node.HasChildNodes)
					{
						foreach (HtmlNode subnode in node.ChildNodes)
							ParseNode(subnode, ref current, ref results);
					}
					break;
			}
		}
	}
}
