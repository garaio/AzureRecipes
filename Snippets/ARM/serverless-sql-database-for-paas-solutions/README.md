For many use cases the workload is not constant and/or the application has longer periods of no usage. If there aren't any periods of inactivity to be expected, this mode may be not the most cost-efficient option (you may [consider the DTU model](../dtu-based-sql-database-for-paas-solutions)). On the other hand, if there are only short periods of activity, the serverless model is likely the most cost-efficient option, considering the rule of dumb that 1 vCore equals ~400 DTUs.

Billing in serverless mode:
* You always pay for the reserved storage capacity (i.e. maximum storage size)
* When the status is "Running", you pay for the actual CPU utilization, which is between the minimum and the maximum vCore capacity
* When the status is "Paused", you don't have compute costs. The only way to get this status, is with the auto-pause configuration after the specified period of inactivity. There is no manual way to change the status. If auto-pausing is disabled (by setting the configuration to `-1`), the database will constantly cost the minimum vCore capacity costs in periods of inactivity.

_Caution: When auto-pausing is enabled, this may cause delays of up to 1 minute on the next requests, which may lead to timeout issues or bad user experience in the application._

Further information:
* [Auto-pausing in serverless mode](https://docs.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview?view=azuresql#auto-pausing), currently not supported if either geo-replication or long-term backup retention shall be enabled
* Hybrid Benefit and Reserved Instances are currently not supported with serverless mode (i.e. no cost-savings possible)

[![Deploy to Azure](https://github.com/garaio/AzureRecipes/raw/master/Resources/deploybutton.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgaraio%2FAzureRecipes%2Fmaster%2FSnippets%2FARM%2Fserverless-sql-database-for-paas-solutions%2Fazuredeploy.bicep)