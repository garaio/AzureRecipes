using System;
using System.Net;

namespace FunctionApp.QnAMaker
{
    public class QnAMakerException : Exception
    {
        public QnAMakerException(HttpStatusCode code, string body, string operation) : base($"{operation} failed: {body}")
        {
            Code = code;
            Body = body;
            Operation = operation;
        }

        public HttpStatusCode Code { get; }
        public string Body { get; }
        public string Operation { get; }
    }
}
