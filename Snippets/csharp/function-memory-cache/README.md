# Introduction
Especially for buffering data with limited validity (such as e.g. access tokens), the in-memory caching can be useful. This snippet shows the likely most simple solution.

# Getting Started
Ensure that following Nuget packes are installed:
* `Microsoft.NET.Sdk.Functions` (tested with 3.0.13)
* `System.Runtime.Caching` (tested with 5.0.0)

Then you can adapt the [function `CacheDemoFunc`](./FunctionApp/Functions/CacheDemoFunc.cs) in your Function App.

# References
* [MSDN Cache in-memory in ASP.NET Core](https://docs.microsoft.com/en-us/aspnet/core/performance/caching/memory?view=aspnetcore-5.0)
