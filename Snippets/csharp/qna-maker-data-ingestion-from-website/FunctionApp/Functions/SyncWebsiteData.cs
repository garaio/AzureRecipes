using FunctionApp;
using FunctionApp.Helpers;
using FunctionApp.QnAMaker;
using FunctionApp.Website;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Diagnostics.CodeAnalysis;
using System.Threading.Tasks;

namespace Garaio.IntranetBot.SyncJobs
{
    public static class SyncWebsiteData
    {
        const string MetadataIdKey = "contentId";

        const string QnAMakerSource = "WebsiteData";

        const string DataBlobNamePattern = "WebsiteData.json";
        const string PageIdLookupBlobName = "WebsitePageIdLookup.json";

        [SuppressMessage("Microsoft.Performance", "IDE0060:ReviewUnusedParameters")]
        [FunctionName(nameof(SyncWebsiteData))]
        public static async Task Run([TimerTrigger("%" + Constants.Configurations.SyncWebsiteSchedule + "%", RunOnStartup = true)] TimerInfo timer, ILogger log)
        {
            log.LogInformation($"Sync Website started");

            // Run Indexer
            var websiteData = await WebsiteIndexerFactory.Create().GetWebsiteData();

            var websiteDataContainer = FunctionHelper.BlobClient.Value.GetContainerReference(Configurations.WebsiteDataContainer);

            // Load and match page-id's
            IList<string> pageLookup = new List<string>();

            var lookupBlobFile = websiteDataContainer.GetBlockBlobReference(PageIdLookupBlobName);
            if (await lookupBlobFile.ExistsAsync())
            {
                var lookupJson = await lookupBlobFile.DownloadTextAsync();

                pageLookup = JsonHelper.FromJson<IList<string>>(lookupJson);
            }
            else
            {
                lookupBlobFile.Properties.ContentType = "application/json";
            }

            foreach (var page in websiteData)
            {
                var index = pageLookup.IndexOf(page.Path);

                if (index >= 0)
                {
                    page.PageId = index;
                }
                else
                {
                    page.PageId = pageLookup.Count;
                    pageLookup.Add(page.Path);
                }
            }

            await lookupBlobFile.UploadTextAsync(JsonHelper.ToJson(pageLookup));

            // Update QnA Maker
            var qnaItems = new List<QnAElement>();
            foreach (var page in websiteData)
            {
                var contents = page.Contents.Where(c => !c.IsEmpty).ToArray();
                if (!contents.Any())
                    continue;

                var numTitles = contents.Count(c => c.Type == TextEntryType.Title);
                var numTexts = contents.Count(c => c.Type != TextEntryType.Title);
                
                var id = page.PageId * 100 + 1;
                var question = string.Empty;
                var answer = string.Empty;

                // One single content
                if (numTitles == 0 || numTexts == 0)
                {
                    question = page.PageName;
                    answer = page.Text;

                    var qnaElement = new QnAElement
                    {
                        Id = id,
                        Questions = new List<string> { TextHelper.ShortenText(question, QnAElement.QuestionMaxLength) },
                        Answer = answer,
                        Metadata = new[] { new QnAMetadata { Name = MetadataIdKey, Value = $"{id}" } },
                        Source = QnAMakerSource
                    };

                    qnaItems.Add(qnaElement);
                    continue;
                }

                // Multiple entries (generic pattern: summarize titles and contents)
                question = answer = string.Empty;

                foreach (var content in contents)
                {
                    if (content.Type == TextEntryType.Title)
                    {
                        if (string.IsNullOrEmpty(answer))
                        {
                            question += (string.IsNullOrEmpty(question) ? string.Empty : Environment.NewLine) + content.Content;
                        }
                        else
                        {
                            question = !string.IsNullOrEmpty(question) ? question : page.PageName;

                            var qnaElement = new QnAElement
                            {
                                Id = id,
                                Questions = new List<string> { TextHelper.ShortenText(question, QnAElement.QuestionMaxLength) },
                                Answer = answer,
                                Metadata = new[] { new QnAMetadata { Name = MetadataIdKey, Value = $"{id}" } },
                                Source = QnAMakerSource
                            };

                            qnaItems.Add(qnaElement);
                            id++;

                            question = content.Content;
                            answer = string.Empty;
                        }
                    }
                    else
                    {
                        answer += (string.IsNullOrEmpty(answer) ? string.Empty : Environment.NewLine) + content.Content;
                    }
                }

                if (!string.IsNullOrEmpty(answer))
                {
                    question = !string.IsNullOrEmpty(question) ? question : page.PageName;
                    
                    var qnaElement = new QnAElement
                    {
                        Id = id,
                        Questions = new List<string> { TextHelper.ShortenText(question, QnAElement.QuestionMaxLength) },
                        Answer = answer,
                        Metadata = new[] { new QnAMetadata { Name = MetadataIdKey, Value = $"{id}" } },
                        Source = QnAMakerSource
                    };

                    qnaItems.Add(qnaElement);
                    id++;
                }
            }

            try
            {
                var client = new QnAMakerClient(Configurations.QnASubscriptionKey, Configurations.QnAKnowledgebaseId);

                await client.ActualizeAllElementsInScope(QnAMakerSource, MetadataIdKey, qnaItems);
            }
            catch (Exception e)
            {
                log.LogError(e, $"Update QnA Maker failed.");
                throw;
            }

            // Generate and update notifications-file in storage account
            var blobName = string.Format(DataBlobNamePattern);
            var dataBlobFile = websiteDataContainer.GetBlockBlobReference(blobName);
            dataBlobFile.Properties.ContentType = "application/json";
            
            await dataBlobFile.UploadTextAsync(JsonHelper.ToJson(websiteData));

            log.LogInformation($"Sync Website ended");
        }
    }
}
