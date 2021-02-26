using System.Collections.Generic;

namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#context"/>
    /// </summary>
    public class QnAContext
    {
        public bool IsContextOnly { get; set; }
        public ICollection<QnAPrompt> Prompts { get; set; }
    }
}
