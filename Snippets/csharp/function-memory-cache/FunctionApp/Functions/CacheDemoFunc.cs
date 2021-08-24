using System;
using System.Net.Http;
using System.Runtime.Caching;
using System.Threading.Tasks;

using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;

namespace FunctionApp.Functions
{
    public static class CacheDemoFunc
    {
        private static readonly MemoryCache _cache = MemoryCache.Default;

        [FunctionName(nameof(GetAccessToken))]
        public static async Task<string> GetAccessToken(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequestMessage req,
            ILogger log)
        {
            const string cacheKey = "Demo.AccessToken";
            object token = _cache.Get(cacheKey);
            if (token != null)
            {
                log.LogInformation("Existing token found, using this.");
                return (string)token;
            }

            // Generate new token
            string newToken = Guid.NewGuid().ToString();

            // Save token to cache
            _cache.Add(cacheKey, newToken, new CacheItemPolicy { SlidingExpiration = TimeSpan.FromMinutes(29) });
            log.LogInformation($"Added token to the cache");

            return newToken;
        }
    }
}