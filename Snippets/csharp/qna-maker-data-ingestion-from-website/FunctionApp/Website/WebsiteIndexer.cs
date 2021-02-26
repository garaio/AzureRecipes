using Abot2.Crawler;
using Abot2.Poco;
using FunctionApp.Helpers;
using HtmlAgilityPack;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace FunctionApp.Website
{
	public class WebsiteIndexer
	{
		private readonly ICollection<PageEntry> _pages = new List<PageEntry>();
		private readonly string _host;

		public WebsiteIndexer(string host, ICollection<string> ignoredPathes = null, int delayPerRequestMilliSeconds = 1000, int maxPagesToCrawl = 1000)
		{
			_host = host;

			var config = new CrawlConfiguration
			{
				MaxPagesToCrawl = maxPagesToCrawl,
				MinCrawlDelayPerDomainMilliSeconds = delayPerRequestMilliSeconds,
				IsExternalPageCrawlingEnabled = false
			};

			Crawler = new PoliteWebCrawler(config)
			{
				ShouldCrawlPageDecisionMaker = (pageToCrawl, crawlContext) =>
				{
					var ignored = string.IsNullOrEmpty(pageToCrawl.Uri?.AbsolutePath) || ignoredPathes?.Any(p => Regex.IsMatch(pageToCrawl.Uri.AbsolutePath, p)) == true;
					if (ignored)
					{
						Console.WriteLine($"Ignored '{pageToCrawl.Uri?.AbsolutePath}'");
						return new CrawlDecision { Allow = false, Reason = "Path matches pattern in blacklist" };
					}

					return new CrawlDecision { Allow = true };
				}
			};

			Crawler.PageCrawlCompleted += PageCrawlCompleted;
		}

		public PoliteWebCrawler Crawler { get; }

		public async Task<IEnumerable<PageEntry>> GetWebsiteData(CancellationToken cancellationToken = default)
		{
			// Remove all existing entries
			_pages.Clear();

			var crawlResult = await Crawler.CrawlAsync(new Uri(_host), CancellationTokenSource.CreateLinkedTokenSource(cancellationToken));

			if (crawlResult.ErrorOccurred)
			{
				Console.WriteLine(crawlResult.ErrorException);
			}

			// Truncate common headers and footers
			if (_pages.Count > 1)
			{
				var areIdentical = false;

				// Headers
				do
				{
					areIdentical = _pages.Select(p => p.Contents.FirstOrDefault()?.Content).Distinct().Count() == 1;

					if (areIdentical)
					{
						foreach (var page in _pages)
							page.Contents.Remove(page.Contents.First());
					}
				} while (areIdentical);

				// Footers
				do
				{
					areIdentical = _pages.Select(p => p.Contents.LastOrDefault()?.Content).Distinct().Count() == 1;

					if (areIdentical)
					{
						foreach (var page in _pages)
							page.Contents.Remove(page.Contents.Last());
					}
				} while (areIdentical);
			}

			return _pages;
		}

		private void PageCrawlCompleted(object sender, PageCrawlCompletedArgs e)
		{
			var httpStatus = e.CrawledPage.HttpResponseMessage.StatusCode;
			if (httpStatus != System.Net.HttpStatusCode.OK)
			{
				Console.WriteLine($"Skipped {e.CrawledPage?.Uri}: HTTP {httpStatus}");
				return;
			}

			var rawPageText = e.CrawledPage?.Content?.Text;
			if (string.IsNullOrWhiteSpace(rawPageText))
			{
				Console.WriteLine($"Skipped {e.CrawledPage?.Uri}: No Content");
				return;
			}

			var htmlDoc = new HtmlDocument();
			htmlDoc.LoadHtml(rawPageText);

			var contents = HtmlParser.ConvertToPlainText(htmlDoc);
			if (!contents.Any())
			{
				Console.WriteLine($"Skipped {e.CrawledPage?.Uri}: No Content");
				return;
			}

			HtmlNode mdnode = htmlDoc.DocumentNode.SelectSingleNode("//meta[@name='description']");
			var description = mdnode?.Attributes["content"]?.Value;

			var title = htmlDoc.DocumentNode.SelectSingleNode("//title")?.InnerText;

			var entry = new PageEntry
			{
				Path = e.CrawledPage?.Uri?.AbsolutePath?.TrimStart('/') ?? string.Empty,
				Link = e.CrawledPage?.Uri?.AbsoluteUri,
				Description = description,
				Title = title,
				Contents = contents
			};

			_pages.Add(entry);
		}
	}

	public static class WebsiteIndexerFactory
	{
		public static WebsiteIndexer Create()
		{
			var host = Environment.GetEnvironmentVariable(Configurations.WebsiteCrawlerHost);

			var ignoreList = Environment.GetEnvironmentVariable(Configurations.WebsiteCrawlerIgnoreList);
			var ignoredPathes = !string.IsNullOrEmpty(ignoreList) ? JsonHelper.FromJson<string[]>(ignoreList) : Array.Empty<string>();

			var delay = int.TryParse(Environment.GetEnvironmentVariable(Configurations.WebsiteCrawlerDelayPerRequestMilliSeconds), out var delayMs) ? delayMs : 1000;

			return new WebsiteIndexer(host, ignoredPathes, delay);
		}
	}
}
