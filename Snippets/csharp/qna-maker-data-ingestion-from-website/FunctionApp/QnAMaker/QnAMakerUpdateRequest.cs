using System.Collections.Generic;

namespace FunctionApp.QnAMaker
{
    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#request-body"/>
    /// </summary>
    public class QnAMakerUpdateRequest
    {
        public QnAMakerAddSet Add { get; set; }

        public QnAMakerUpdateSet Update { get; set; }

        public QnAMakerDeleteSet Delete { get; set; }
    }

    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#add"/>
    /// </summary>
    public class QnAMakerAddSet
    {
        public ICollection<QnAElement> QnaList { get; set; }
    }

    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#update"/>
    /// </summary>
    public class QnAMakerUpdateSet
    {
        public string Name { get; set; }
        public ICollection<QnAElementUpdate> QnaList { get; set; }
    }

    /// <summary>
    /// See <see href="https://docs.microsoft.com/de-de/rest/api/cognitiveservices/qnamaker/knowledgebase/update#delete"/>
    /// </summary>
    public class QnAMakerDeleteSet
    {
        public ICollection<int> Ids { get; set; }
        public ICollection<string> Sources { get; set; }
    }
}
