# Introduction
Azure Functions provides input bindings which allow access to external systems in a very comfortable way. However if you want to test the function locally this may be tricky as the binding cannot be resolved. One typical example is the [binding for Microsoft Graph](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-microsoft-graph). This sample shows a possible pattern to take advantage of the input binding but also be able to test it locally.

# Getting Started
Create an App Registration and assign in to Function (you take [`azuredeploy.json`](./azuredeploy.json) as a basis). Create an additional secret on it and copy the accoring settings to `local.settings.json` (avoid to commit sensitive data to the source management).

# Deployment (Azure Resources)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2Fcsharp%2Ffunction-user-auth-token-local%2Fazuredeploy.json)
