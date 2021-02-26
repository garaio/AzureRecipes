using System.Collections.Generic;

namespace FunctionApp.QnAMaker
{
    public class QnAMakerGetResponse
    {
        public ICollection<QnAElement> QnaDocuments { get; set; }
    }
}
