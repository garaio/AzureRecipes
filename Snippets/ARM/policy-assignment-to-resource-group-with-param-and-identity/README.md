# Introduction
This sample assigns the built-in policy ["Inherit a tag from the resource group if missing"](https://github.com/Azure/azure-policy/blob/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json) to a resource group. This policy definition contains a required parameter as well as the assignment of a managed identity which is not documented well on MSDN or [ARM templates reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/policyassignments).

**Important**: The deployment of policy assignments needs according permissions which are not included to the usually used role `Contributor`. You may assigne the role `Resource Policy Contributor` to the service principal used for deployment.

# Deployment
[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Fpolicy-assignment-to-resource-group-with-param-and-identity%2Fazuredeploy.bicep)