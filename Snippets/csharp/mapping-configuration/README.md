# Introduction
Especially for integration scenarios there is often the need to provide a simple configuration for mappings. This may include property mappings but also routing configurations ("if this value, then that service"). This snippet provides a simple base class to define such mappings with easy editable JSON configurations, typically stored in a Blob Storage. It supports complex requirements such as resolution based on multiple criterias, wildcard support and fallback / default mechanism.

The snippet demonstrates a usage in an Azure Function, but it can be easily used in any C# code without any dependencies other than Newtonsoft JSON.

# Getting Started
Create mapping configurations like this ([`demo-content-type-mapping`](./demo-content-type-mapping.json)):
```json
{
    "Image:psd": "PSD",
    "Image:*": "PHOTO",
    "Movie:*": "VIDEO",
    "*:pdf": "PDF",
    "MS PowerPoint:*": "PRESENTATION",
    "MS Excel:*": "EXCEL",
    "MS Word:doc": "DOC",
    "MS Word:docx": "DOCX",
	"*": "OTHER"
}
```

Features:
* Multiple criterias which are resolved. These are separated with ':' and are not limited
* Wildcard support with '*' (matches any number of characters)
* Order of definitions is relevant, only the first match is resolved. This way you can define default / fallback values at the end
* Supports any value type which can be deserialized by Newtonsoft JSON. The sample above shows the usage with string values, but you can also define mappings for e.g. integers like `"*:pdf": 42`. All values have to be of same type

You can then parse and use this file in any place like:
```csharp
Mapping<string> contentTypeMapping = Mapping<string>.CreateFromFileContent(mappingFileContent);

string contentType = contentTypeMapping.GetMatchOrDefault("Movie", "mp4"); // Returns VIDEO
```

