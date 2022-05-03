# Virtual Agent
This blueprint contains the resources to build a Virtual Agent which implements processes and helps the users with answers to questions. It consists of a Bot Framework based App Service with interacts with the Cognitive Services LUIS and QnA Maker, the latter being integrated with enterprise data sources.

Consider [this knowledge base article for an overview of Bot Framework components](../../Knowledge/Knowhow-AzureBotService-Overview).

## Architecture
![Architecture](./Architecture.png)

[![Get draw.io File](https://github.com/garaio/AzureRecipes/raw/master/Resources/getdrawiobutton.svg?sanitize=true)](./Architecture.drawio)
[![Estimate](https://github.com/garaio/AzureRecipes/raw/master/Resources/estimatebutton.svg?sanitize=true)](https://azure.com/e/cc6ec55be5454a59901ffc8c69706d3f)

## Implementation Notes
### Bot Framework Resources
* [MSDN Azure Bot Service Documentation](https://docs.microsoft.com/en-us/azure/bot-service/?view=azure-bot-service-4.0)
* [Github Bot Framework Resources](https://github.com/microsoft/botframework-sdk)

### Indexer Function
This [snippet provides a reference implementation](../../Snippets/csharp/qna-maker-data-ingestion-from-website) and shows the ingestion of data automatically extracted from a website.

## Deployment
Bot Framework solutions are normally built based on either the [Bot Framework Solution "Virtual Assistant" template](https://microsoft.github.io/botframework-solutions/virtual-assistant/tutorials/create-assistant/csharp/4-provision-your-azure-resources/) or with the [Bot Framework Composer](https://github.com/microsoft/BotFramework-Composer). Both include the Azure core resource definitions and an according deployment procedure as follows:
* [Bot Framework Solution deployment template](https://github.com/microsoft/botframework-solutions/tree/master/samples/csharp/assistants/virtual-assistant/VirtualAssistantSample/Deployment/Resources)
* [Bot Framework Composer deployment manual](https://docs.microsoft.com/en-us/composer/how-to-publish-bot)

This deployment script contains some additional components as defined in the architecture and needs to be merged or validated with the deployment result from the template used.

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FBlueprints%2Fvirtual-agent%2Fazuredeploy.json)
[![Visualize](https://github.com/garaio/AzureRecipes/raw/master/Resources/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FBlueprints%2Fvirtual-agent%2Fazuredeploy.json)