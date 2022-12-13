# Search Engine
This blueprint contains the base resources to create a central, independent search engine that delivers results from multiple data sources and enriches them with intelligent suggestions.

## Architecture
![Architecture](./Architecture.png)

[![Get draw.io File](https://github.com/garaio/AzureRecipes/raw/master/Resources/getdrawiobutton.svg?sanitize=true)](./Architecture.drawio)
[![Estimate](https://github.com/garaio/AzureRecipes/raw/master/Resources/estimatebutton.svg?sanitize=true)](https://azure.com/e/9394f7312c074729993a3738d4fbbb44)

## Implementation Notes
### Test App (Search UI)
As basis you may use the [Cognitive Search Question Answering Solution Accelerator](https://github.com/Azure-Samples/search-qna-maker-accelerator) which includes a simple UI (React application).

## Deployment
[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FBlueprints%2Fsearch-engine%2Fazuredeploy.bicep)