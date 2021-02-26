using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/en-us/azure/cognitive-services/qnamaker/quickstarts/csharp#download-the-contents-of-a-knowledge-base"/>
    /// </summary>
    public class QnAMakerClient
    {
        private const string host = "https://westus.api.cognitive.microsoft.com";
        private const string service = "/qnamaker/v4.0";
        private const int updateBatchSize = 100;

        private readonly string _subscriptionKey;
        private readonly string _knowledgebaseId;
        private readonly string _environment; // NOTE: May either have value "test" or "prod".

        public QnAMakerClient(string subscriptionKey, string knowledgebaseId, bool isTest = false)
        {
            _subscriptionKey = subscriptionKey;
            _knowledgebaseId = knowledgebaseId;
            _environment = isTest ? "test" : "prod";
        }

        private async Task<Response> Get(string uri)
        {
            using (var client = new HttpClient())
            using (var request = new HttpRequestMessage())
            {
                request.Method = HttpMethod.Get;
                request.RequestUri = new Uri(uri);
                request.Headers.Add("Ocp-Apim-Subscription-Key", _subscriptionKey);

                var response = await client.SendAsync(request);

                return await Response.Create(response);
            }
        }

        private async Task<Response> Patch(string uri, string body)
        {
            using (var client = new HttpClient())
            using (var request = new HttpRequestMessage())
            {
                request.Method = new HttpMethod("PATCH");
                request.RequestUri = new Uri(uri);
                request.Content = new StringContent(body, Encoding.UTF8, "application/json");
                request.Headers.Add("Ocp-Apim-Subscription-Key", _subscriptionKey);

                var response = await client.SendAsync(request);

                return await Response.Create(response);
            }
        }

        private async Task<Response> Post(string uri)
        {
            using (var client = new HttpClient())
            using (var request = new HttpRequestMessage())
            {
                request.Method = HttpMethod.Post;
                request.RequestUri = new Uri(uri);
                request.Headers.Add("Ocp-Apim-Subscription-Key", _subscriptionKey);

                var response = await client.SendAsync(request);

                return await Response.Create(response);
            }
        }

        private async Task<Response> GetStatus(string operation)
        {
            string uri = host + service + operation;

            return await Get(uri);
        }

        private async Task UpdateBulk(ICollection<int> deleteIdSet, ICollection<QnAElement> addSet, ICollection<QnAElementUpdate> updateSet)
        {
            var qnaRequest = new QnAMakerUpdateRequest();

            if (deleteIdSet?.Count > 0)
                qnaRequest.Delete = new QnAMakerDeleteSet { Ids = deleteIdSet };
            if (addSet?.Count > 0)
                qnaRequest.Add = new QnAMakerAddSet { QnaList = addSet };
            if (updateSet?.Count > 0)
                qnaRequest.Update = new QnAMakerUpdateSet { Name = null, QnaList = updateSet };

            if (qnaRequest.Delete != null || qnaRequest.Add != null || qnaRequest.Update != null)
            {
                await Update(qnaRequest);
            }
        }

        private async Task UpdateBatchwise(ICollection<int> deleteIdSet, ICollection<QnAElement> addSet, ICollection<QnAElementUpdate> updateSet)
        {
            var delCount = deleteIdSet?.Count ?? 0;
            var addCount = addSet?.Count ?? 0;
            var updCount = updateSet?.Count ?? 0;
            var totalCount = delCount + addCount + updCount;

            if (totalCount == 0)
                return;

            if (totalCount <= updateBatchSize)
            {
                await UpdateBulk(deleteIdSet, addSet, updateSet);
                return;
            }

            var counter = 0;
            while (counter < totalCount)
            {
                var setSize = updateBatchSize;
                var qnaRequest = new QnAMakerUpdateRequest();

                if (setSize > 0 && delCount > counter)
                {
                    var set = deleteIdSet.Skip(counter).Take(setSize).ToArray();

                    setSize -= set.Length;
                    counter += set.Length;

                    qnaRequest.Delete = new QnAMakerDeleteSet { Ids = set };
                }
                if (setSize > 0 && delCount + addCount > counter)
                {
                    var set = addSet.Skip(counter - delCount).Take(setSize).ToArray();

                    setSize -= set.Length;
                    counter += set.Length;

                    qnaRequest.Add = new QnAMakerAddSet { QnaList = set };
                }
                if (setSize > 0 && delCount + addCount + updCount > counter)
                {
                    var set = updateSet.Skip(counter - delCount - addCount).Take(setSize).ToArray();

                    setSize -= set.Length;
                    counter += set.Length;

                    qnaRequest.Update = new QnAMakerUpdateSet { Name = null, QnaList = set };
                }

                await Update(qnaRequest);
            }
        }

        public async Task<QnAMakerGetResponse> Get()
        {
            var method = "/knowledgebases/{0}/{1}/qna/";
            var method_with_id = string.Format(method, _knowledgebaseId, _environment);
            var uri = host + service + method_with_id;

            var response = await Get(uri);

            return JsonConvert.DeserializeObject<QnAMakerGetResponse>(response.Body);
        }

        public async Task Update(QnAMakerUpdateRequest request)
        {
            var payload = JsonConvert.SerializeObject(request);

            var method = "/knowledgebases/";
            string uri = host + service + method + _knowledgebaseId;
            var response = await Patch(uri, payload);

            response.EnsureSuccess();

            var operation = response.Headers.TryGetValues("Location", out var locationHeaders) ? locationHeaders.FirstOrDefault() : null;
            if (string.IsNullOrEmpty(operation))
                return;

            var done = false;
            while (true != done)
            {
                response = await GetStatus(operation);

                var state = JToken.Parse(response.Body)?.Value<string>("operationState") ?? string.Empty;
                if (state.CompareTo("Running") == 0 || state.CompareTo("NotStarted") == 0)
                {
                    var wait = response.Headers.TryGetValues("Retry-After", out var retryHeaders) ? retryHeaders.FirstOrDefault() : null;
                    var waitInSeconds = int.TryParse(wait ?? string.Empty, out var waitParse) ? waitParse : 30;

                    Thread.Sleep(waitInSeconds * 1000);
                }
                else
                {
                    done = true;
                }
            }
        }

        public async Task Publish()
        {
            var method = "/knowledgebases/";
            var uri = host + service + method + _knowledgebaseId;

            var response = await Post(uri);

            response.EnsureSuccess();
        }

        public async Task ActualizeAllElementsInScope(string scope, string metadataIdKey, ICollection<QnAElement> elements)
        {
            var currentElements = await Get();
            if (currentElements?.QnaDocuments == null)
            {
                // There is an error within QnA Maker itself (appears to happen sometimes). Forget this iteration and try it again next time...
                return;
            }

            var currentIdLookup = currentElements.QnaDocuments
                .Where(q => q.Source == scope && q.Metadata?.Any(m => string.Equals(m.Name, metadataIdKey, StringComparison.OrdinalIgnoreCase)) == true)
                .ToLookup(q => int.TryParse(q.Metadata.First(m => string.Equals(m.Name, metadataIdKey, StringComparison.OrdinalIgnoreCase)).Value ?? string.Empty, out var id) ? id : -1);
            var newIdLookup = elements.ToLookup(e => e.Id);

            var addSet = newIdLookup.Where(q => !currentIdLookup.Contains(q.Key)).Select(g => g.First()).ToArray();
            var deleteIdSet = new List<int>();
            var updateSet = new List<QnAElementUpdate>();

            foreach (var idSet in currentIdLookup)
            {
                // Ignore elements which aren't linked to a source id
                if (idSet.Key < 0)
                {
                    continue;
                }

                // Delete all if source with this id isn't available anymore (normally there aren't multiple entries with same id)
                if (!newIdLookup.Contains(idSet.Key))
                {
                    deleteIdSet.AddRange(idSet.Select(e => e.Id));
                }
                else
                {
                    // As a lookup is a grouping it may have multiple entries with the same id (rather theoretic and would indicate a bug somewhere). Delete them so that only one remains
                    deleteIdSet.AddRange(idSet.Skip(1).Select(e => e.Id));

                    var existingEntity = idSet.First();
                    var newEntity = newIdLookup[idSet.Key].First();
                    var entity = new QnAElementUpdate
                    {
                        Id = existingEntity.Id,
                        Answer = newEntity.Answer,
                        Context = newEntity.Context,
                        Source = newEntity.Source,
                        Metadata = new QnAMetadataUpdateSet
                        {
                            // Currently no change of Metadata foreseen
                        },
                        Questions = new QnAQuestionUpdateSet
                        {
                            Add = newEntity.Questions.Except(existingEntity.Questions).ToArray()
                            // Currently no deletion of questions foreseen. If so wanted this should be noted in a metadata-value to prevent data-loss on subsequent changes
                        }
                    };

                    updateSet.Add(entity);
                }
            }

            await UpdateBatchwise(deleteIdSet, addSet, updateSet);
            await Publish();
        }

        private struct Response
        {
            public bool Success;
            public HttpStatusCode Code;
            public HttpResponseHeaders Headers;
            public string Body;

            public static async Task<Response> Create(HttpResponseMessage response)
            {
                return new Response
                {
                    Body = await response.Content.ReadAsStringAsync(),
                    Code = response.StatusCode,
                    Success = response.IsSuccessStatusCode,
                    Headers = response.Headers
                };
            }

            public void EnsureSuccess([System.Runtime.CompilerServices.CallerMemberName] string operation = "UndefinedOperation")
            {
                if (Success)
                    return;

                throw new QnAMakerException(Code, Body, operation);
            }
        }
    }
}
