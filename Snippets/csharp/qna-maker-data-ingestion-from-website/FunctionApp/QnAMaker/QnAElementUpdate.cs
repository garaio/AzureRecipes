using System.Collections.Generic;

namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#updateqnadto"/>
    /// </summary>
    public class QnAElementUpdate : QnAElementBase
    {
        public QnAQuestionUpdateSet Questions { get; set; }
        public QnAMetadataUpdateSet Metadata { get; set; }
    }

    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#questions"/>
    /// </summary>
    public class QnAQuestionUpdateSet
    {
        public ICollection<string> Add { get; set; }
        public ICollection<string> Delete { get; set; }
    }
}
