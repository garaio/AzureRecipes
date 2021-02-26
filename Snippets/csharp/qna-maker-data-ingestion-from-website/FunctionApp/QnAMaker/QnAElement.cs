using System.Collections.Generic;

namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#qna"/>
    /// </summary>
    public class QnAElement : QnAElementBase
    {
        public const int QuestionMaxLength = 1000;

        public ICollection<string> Questions { get; set; } = new List<string>();
        public ICollection<QnAMetadata> Metadata { get; set; }
    }
}
