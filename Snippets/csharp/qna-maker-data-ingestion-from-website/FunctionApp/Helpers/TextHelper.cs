namespace FunctionApp.Helpers
{
	public static class TextHelper
	{
		public static int CountWords(string plainText)
		{
			return !string.IsNullOrEmpty(plainText) ? plainText.Split(' ', '\n').Length : 0;
		}

		public static string ShortenText(string text, int length)
		{
			if (!string.IsNullOrEmpty(text) && text.Length > length)
			{
				text = text.Substring(0, length - 4) + " ...";
			}
			return text;
		}
	}
}
