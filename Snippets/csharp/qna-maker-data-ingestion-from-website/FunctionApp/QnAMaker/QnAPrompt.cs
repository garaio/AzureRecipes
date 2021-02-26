namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#promptdto"/>
    /// </summary>
    public class QnAPrompt
    {
        public int DisplayOrder { get; set; }
        public string DisplayText { get; set; }
        public int QnaId { get; set; }
        public QnAElement Qna { get; set; }
    }
}
