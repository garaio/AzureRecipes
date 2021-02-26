using System.Collections.Generic;

namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#metadatadto"/>
    /// </summary>
    public class QnAMetadata
    {
        public string Name { get; set; }
        public string Value { get; set; }
    }

    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#metadata"/>
    /// </summary>
    public class QnAMetadataUpdateSet
    {
        public ICollection<QnAMetadata> Add { get; set; }
        public ICollection<QnAMetadata> Delete { get; set; }
    }
}
