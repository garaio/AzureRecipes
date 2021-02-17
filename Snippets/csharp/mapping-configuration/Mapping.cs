using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

using Newtonsoft.Json.Linq;

namespace FunctionApp.Common
{
    public class Mapping<TValue>
    {
        private readonly IList<KeyValuePair<string, TValue>> _mapping;

        protected Mapping(IList<KeyValuePair<string, TValue>> mapping)
        {
            _mapping = mapping;
        }

        public static Mapping<TValue> CreateFromFileContent(string content)
        {
            if (string.IsNullOrWhiteSpace(content))
            {
                return new Mapping<TValue>(Array.Empty<KeyValuePair<string, TValue>>());
            }

            var keyValuePairs = JObject.Parse(content)
                .Children()
                .Where(c => c.HasValues)
                .OfType<JProperty>()
                .Select(c => new KeyValuePair<string, TValue>(WildCardToRegular(c.Name), c.Values<TValue>().First()))
                .ToArray();

            return new Mapping<TValue>(keyValuePairs);
        }

        public static Mapping<TValue> CreateFromList(IList<KeyValuePair<string, TValue>> mapping)
        {
            if (mapping == null || !mapping.Any())
            {
                return new Mapping<TValue>(Array.Empty<KeyValuePair<string, TValue>>());
            }

            return new Mapping<TValue>(mapping);
        }

        public IEnumerable<KeyValuePair<string, TValue>> Values => _mapping.AsEnumerable();

        public TValue GetMatchOrDefault(params string[] sourceValues)
        {
            var sourceValue = string.Join(":", sourceValues);

            return _mapping.FirstOrDefault(m => Regex.IsMatch(sourceValue, m.Key)).Value;
        }

        private static string WildCardToRegular(string value)
        {
            return "^" + Regex.Escape(value).Replace("\\*", ".*") + "$";
        }
    }
}
