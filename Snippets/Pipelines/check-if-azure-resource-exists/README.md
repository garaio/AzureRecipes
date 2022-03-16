# Overview
Often deployments depend on wheter a resource already exists or has to be newly setup. Currently there is no possibility in Bicep/ARM templates to check the existance and act based on that. So this information needs to be provided as parameter from external, typically within DevOps pipelines.

Note: For most resource types, there is a specific variant (e.g. `az keyvault list`) if you want ensure no mismatches

```yaml
- task: AzureCLI@2
  displayName: 'Determine if Azure Resource exists'
  inputs:
    azureSubscription: '${{ parameters.armServiceConnection }}'
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      resourceCount=$(az resource list --query "[?name=='$(resourceName)'] | length(@)" --subscription $(subscriptionId))
      if [ $resourceCount -gt 0 ]; then
        echo "##vso[task.setvariable variable=resourceExists;]true"
      else
        echo "##vso[task.setvariable variable=resourceExists;]false"
      fi
```
