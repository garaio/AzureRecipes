namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#qna"/>
    /// </summary>
    public abstract class QnAElementBase
    {
        public int Id { get; set; }
        public string Answer { get; set; }
        public string Source { get; set; }
        public QnAContext Context { get; set; }
    }
}
