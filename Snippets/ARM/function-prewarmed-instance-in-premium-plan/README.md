The setup of always running functions with Premium plans consists of two steps:
* App Service Plan with configuration of scale-up setting (SKU: EP1-3) and scale-out settings (minimum/maximum instances used for all assigned Function Apps)
* Function App with site-config properties for scale-out

**Note #1**: There are two similar-looking properties `minimumElasticInstanceCount` (= always ready instances) and `preWarmedInstanceCount` (= pre-warmed instances) - see [according explanation on MSDN](https://docs.microsoft.com/en-us/azure/azure-functions/functions-premium-plan#always-ready-instances).

**Note #2**: You can achieve a similar availability behaviour by using a dedicated App Service plan as used for regular Web Apps and then set the property `alwaysOn` to true. See [this documentation](https://docs.microsoft.com/en-us/azure/azure-functions/functions-scale#always-on) for more details. With that approach you're losing the "serverless" manner and need to define scaling by your own.

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Ffunction-prewarmed-instance-in-premium-plan%2Fazuredeploy.json)