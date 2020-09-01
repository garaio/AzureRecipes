# Introduction
Azure Functions provides input bindings which allow access to external systems in a very comfortable way. However if you want to test the function locally this may be tricky as the binding cannot be resolved. One typical example is the [binding for Microsoft Graph](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-microsoft-graph). This sample shows a possible pattern to take advantage of the input binding but also be able to test it locally.

# Getting Started
Create an App Registration and assign in to Function (you take [`azuredeploy.json`](./azuredeploy.json) as a basis). Create an additional secret on it and copy the accoring settings to `local.settings.json` (avoid to commit sensitive data to the source management).
